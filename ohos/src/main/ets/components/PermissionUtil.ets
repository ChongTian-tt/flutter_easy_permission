/*
 * Copyright (C) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");

 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { abilityAccessCtrl, bundleManager, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { FlutterManager, Log } from '@ohos/flutter_ohos';
import { PermissionCallback, PermissionResult } from './PermissionConstants';

const TAG = 'PermissionUtil';

/**
 * 权限工具类（单例）
 * 封装 HarmonyOS abilityAccessCtrl 权限检查与申请逻辑
 */
export default class PermissionUtil {
  private static instance: PermissionUtil;
  private context: common.UIAbilityContext;
  private atManager: abilityAccessCtrl.AtManager;
  private tokenId: number = 0;

  private constructor() {
    this.context = FlutterManager.getInstance().getUIAbility().context;
    this.atManager = abilityAccessCtrl.createAtManager();
    this.tokenId = this.resolveTokenId();
    Log.i(TAG, `initialized, tokenId=${this.tokenId}`);
  }

  public static getInstance(): PermissionUtil {
    if (!PermissionUtil.instance) {
      PermissionUtil.instance = new PermissionUtil();
    }
    return PermissionUtil.instance;
  }

  public getContext(): common.UIAbilityContext {
    return this.context;
  }

  /** 检查所有权限是否已授权 */
  public hasPermissions(nameArray: string[]): boolean {

    Log.i(TAG, `hasPermissions : ${nameArray.length}`);
    if (!nameArray || nameArray.length === 0) {
      return false;
    }
    for (const name of nameArray) {
      if (!this.checkSinglePermission(name)) {
        return false;
      }
    }
    return true;
  }

  /** 请求权限，结果通过 callback 回传到 Dart */
  public async requestPermissions(
    nameArray: string[],
    callback: PermissionCallback | null,
    requestCode: number
  ): Promise<PermissionResult> {
    const result: PermissionResult = { requestCode, grantedPermissions: [], deniedPermissions: [] };
    if (!nameArray || nameArray.length === 0) {
      return result;
    }

    const permissions = this.toPermissionsArray(nameArray);

    // 已全部授权，直接回调
    if (this.hasPermissions(nameArray)) {
      result.grantedPermissions = [...nameArray];
      callback?.onPermissionGranted(permissions, requestCode);
      return result;
    }

    return this.doRequest(permissions, nameArray, callback, result);
  }

  /**
   * 判断被拒绝的权限中是否存在永久拒绝
   * 依据 requestPermissionsFromUser 返回的 dialogShownResults：
   *   dialogShownResults[i] === false 且 authResults[i] === DENIED → 永久拒绝
   */
  public isPermanentlyDenied(
    authResults: Array<number>,
    dialogShownResults: Array<boolean>
  ): boolean {
    for (let i = 0; i < authResults.length; i++) {
      if (authResults[i] !== abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED
        && dialogShownResults[i] === false) {
        return true;
      }
    }
    return false;
  }

  private resolveTokenId(): number {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      return bundleInfo.appInfo.accessTokenId;
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `resolveTokenId failed: ${err.code}, ${err.message}`);
      return 0;
    }
  }

  private checkSinglePermission(name: string): boolean {
    try {
      const status = this.atManager.checkAccessTokenSync(this.tokenId, name as Permissions);
      Log.i(TAG, `checkAccessToken SUCCESS: ${status}`);
      return status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `checkAccessToken failed: ${err.code}, ${err.message}`);
      return false;
    }
  }

  /** 发起系统权限弹窗 */
  private async doRequest(
    permissions: Array<Permissions>,
    nameArray: string[],
    callback: PermissionCallback | null,
    result: PermissionResult
  ): Promise<PermissionResult> {
    try {
      // 这里是否需要换成二次请求的方法 requestPermissionOnSetting
      const data = await this.atManager.requestPermissionsFromUser(this.context, permissions);

      Log.i(TAG, `doRequest data: ${JSON.stringify(data)}`);
      this.classifyResults(data.authResults, nameArray, result);
      const isPermanent = data.dialogShownResults
        ? this.isPermanentlyDenied(data.authResults, data.dialogShownResults)
        : false;
      Log.i(TAG, `doRequest isPermanent: ${isPermanent}`);

      // 如果存在永久拒绝的权限，尝试 requestPermissionOnSetting 二次请求（API 12+）
      if (isPermanent && result.deniedPermissions.length > 0) {
        await this.tryRequestOnSetting(result, callback);
        return result;
      }

      this.notifyCallback(callback, result, isPermanent);
    } catch (error) {
      Log.e(TAG, `requestPermissionsFromUser error: ${JSON.stringify(error)}`);
      callback?.onPermissionDenied(permissions, result.requestCode, false);
    }
    return result;
  }

  /**
   * 永久拒绝后自动尝试 requestPermissionOnSetting 二次请求
   * 成功则更新结果并回调；失败则以永久拒绝状态回调
   */
  private async tryRequestOnSetting(
    result: PermissionResult,
    callback: PermissionCallback | null
  ): Promise<void> {
    const deniedNames = [...result.deniedPermissions];
    const deniedPerms = this.toPermissionsArray(deniedNames);

    Log.i(TAG, `tryRequestOnSetting: deniedNames=${deniedNames.length}, deniedPerms=${deniedPerms.length}`);
    Log.i(TAG, `tryRequestOnSetting: deniedPerms=${JSON.stringify(deniedPerms)}`);

    try {
      const statuses = await this.atManager.requestPermissionOnSetting(this.context, deniedPerms);
      Log.i(TAG, `tryRequestOnSetting statuses= ${statuses}`);
      const newGranted: string[] = [];
      const newDenied: string[] = [];
      for (let i = 0; i < statuses.length; i++) {
        if (statuses[i] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          newGranted.push(deniedNames[i]);
        } else {
          newDenied.push(deniedNames[i]);
        }
      }
      result.grantedPermissions.push(...newGranted);
      result.deniedPermissions = newDenied;
      Log.i(TAG, `requestPermissionOnSetting: newGranted=${newGranted.length}, stillDenied=${newDenied.length}`);
      this.notifyCallback(callback, result, newDenied.length > 0);
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `tryRequestOnSetting failed: ${err.code}, ${err.message}`);
      // 二次请求失败（权限不同组/不支持等），回退为永久拒绝
      this.notifyCallback(callback, result, true);
    }
  }

  /** 将 authResults 分类为 granted / denied */
  private classifyResults(
    authResults: Array<number>,
    nameArray: string[],
    result: PermissionResult
  ): void {
    for (let i = 0; i < authResults.length; i++) {
      if (authResults[i] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        result.grantedPermissions.push(nameArray[i]);
      } else {
        result.deniedPermissions.push(nameArray[i]);
      }
    }
    Log.i(TAG, `granted:${result.grantedPermissions.length}, denied:${result.deniedPermissions.length}`);
  }

  /** 按 granted / denied 分别回调 */
  private notifyCallback(
    callback: PermissionCallback | null,
    result: PermissionResult,
    isPermanent: boolean
  ): void {
    if (!callback) {
      return;
    }
    const grantedPerms = this.toPermissionsArray(result.grantedPermissions);
    const deniedPerms = this.toPermissionsArray(result.deniedPermissions);

    if (grantedPerms.length > 0) {
      callback.onPermissionGranted(grantedPerms, result.requestCode);
    }
    if (deniedPerms.length > 0) {
      callback.onPermissionDenied(deniedPerms, result.requestCode, isPermanent);
    }
  }

  private toPermissionsArray(names: string[]): Array<Permissions> {
    return names.map(n => n as Permissions);
  }
}

