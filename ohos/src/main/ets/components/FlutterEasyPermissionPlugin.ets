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
import {
  FlutterPlugin,
  FlutterPluginBinding,
  Log,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { Permissions, Want } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import {
  CALLBACK_ON_DENIED,
  CALLBACK_ON_GRANTED,
  CALLBACK_ON_SETTINGS_RETURNED,
  CHANNEL_CALLBACK,
  CHANNEL_PERMISSIONS,
  DEFAULT_RATIONALE,
  DEFAULT_SETTINGS_NEGATIVE,
  DEFAULT_SETTINGS_POSITIVE,
  DEFAULT_SETTINGS_RATIONALE,
  DEFAULT_SETTINGS_TITLE,
  DialogConfig,
  METHOD_HAS_PERMISSIONS,
  METHOD_REQUEST_PERMISSIONS,
  METHOD_SHOW_SETTINGS_DIALOG,
  PermissionCallback,
  PermissionOhosList,
} from './PermissionConstants';
import PermissionUtil from './PermissionUtil';

const TAG = 'FlutterEasyPermissionPlugin';

/** FlutterEasyPermissionPlugin **/
export default class FlutterEasyPermissionPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private callbackChannel: MethodChannel | null = null;
  private permissionCallback: PermissionCallbackImpl | null = null;
  private rationalePermissionNames: Set<string> = new Set<string>();

  getUniqueClassName(): string {
    return 'FlutterEasyPermissionPlugin';
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_PERMISSIONS);
    this.channel.setMethodCallHandler(this);
    this.callbackChannel = new MethodChannel(binding.getBinaryMessenger(), CHANNEL_CALLBACK);
    this.permissionCallback = new PermissionCallbackImpl(this.callbackChannel, this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    Log.i(TAG, 'onDetachedFromEngine');
    if (this.channel) {
      this.channel.setMethodCallHandler(null);
      this.channel = null;
    }
    this.callbackChannel = null;
    this.permissionCallback = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case METHOD_HAS_PERMISSIONS:
        this.handleHasPermissions(call, result);
        break;
      case METHOD_REQUEST_PERMISSIONS:
        this.handleRequestPermissions(call, result);
        break;
      case METHOD_SHOW_SETTINGS_DIALOG:
        this.handleShowSettingsDialog(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  /** 检查权限是否已授予 */
  private handleHasPermissions(call: MethodCall, result: MethodResult): void {
    const permNames = this.resolvePermissionNames(call);
    if (permNames.length === 0) {
      result.success(false);
      return;
    }
    const granted = PermissionUtil.getInstance().hasPermissions(permNames);
    Log.i(TAG, `hasPermissions=${granted}, perms=${permNames}`);
    result.success(granted);
  }

  /** 请求权限（可选 rationale 弹窗） */
  private handleRequestPermissions(call: MethodCall, result: MethodResult): void {
    const record = call.args as Map<string, Object>;
    const rationale = record.get('rationale') as string;
    const requestCode = (record.get('requestCode') as number) ?? 0;
    const permNames = this.resolvePermissionNames(call);

    // 先检查是否已全部授权，已授权则直接回调 onGranted，不弹任何框
    if (PermissionUtil.getInstance().hasPermissions(permNames)) {
      Log.i(TAG, `All permissions already granted, skip dialog`);
      const perms = permNames.map(n => n as Permissions);
      this.permissionCallback?.onPermissionGranted(perms, requestCode);
      result.success(null);
      return;
    }

    if (this.shouldShowRationale(permNames, rationale)) {
      this.showRationaleAndRequest(permNames, rationale, requestCode);
    } else {
      this.doRequestPermissions(permNames, requestCode);
    }
    // MethodChannel 不阻塞，立即返回
    result.success(null);
  }

  /** 展示设置页跳转对话框 */
  private handleShowSettingsDialog(call: MethodCall, result: MethodResult): void {
    const record = call.args as Map<string, Object>;
    const config: DialogConfig = {
      title: (record.get('title') as string) ?? DEFAULT_SETTINGS_TITLE,
      message: (record.get('rationale') as string) ?? DEFAULT_SETTINGS_RATIONALE,
      positiveText: (record.get('positiveButtonText') as string) ?? DEFAULT_SETTINGS_POSITIVE,
      negativeText: (record.get('negativeButtonText') as string) ?? DEFAULT_SETTINGS_NEGATIVE,
    };
    this.showSettingsDialog(config);
    result.success(null);
  }

  /** 发起权限请求（无 rationale） */
  private async doRequestPermissions(permNames: string[], requestCode: number): Promise<void> {
    await PermissionUtil.getInstance()
      .requestPermissions(permNames, this.permissionCallback, requestCode);
  }

  /** 仅在权限曾被拒绝后，再次请求时展示 rationale，对齐 Android 行为 */
  private shouldShowRationale(permNames: string[], rationale: string): boolean {
    if (!rationale || rationale.length === 0) {
      return false;
    }
    for (const name of permNames) {
      if (this.rationalePermissionNames.has(name)) {
        return true;
      }
    }
    return false;
  }

  markGrantedPermissions(permissions: Array<Permissions>): void {
    for (const permission of permissions) {
      this.rationalePermissionNames.delete(permission.toString());
    }
  }

  markDeniedPermissions(permissions: Array<Permissions>): void {
    for (const permission of permissions) {
      this.rationalePermissionNames.add(permission.toString());
    }
  }

  /** 先展示 rationale 对话框，用户确认后再请求权限 */
  private showRationaleAndRequest(permNames: string[], rationale: string, requestCode: number): void {
    promptAction.showDialog({
      title: rationale ?? DEFAULT_RATIONALE,
      buttons: [{ text: '确定', color: '#007DFF' }, { text: '取消', color: '#FF0000' }]
    }).then(async (dialogResult) => {
      if (dialogResult.index === 0) {
        await this.doRequestPermissions(permNames, requestCode);
        return;
      }
      // 用户取消 rationale 弹框 → 视为拒绝
      const perms = permNames.map(n => n as Permissions);
      this.permissionCallback?.onPermissionDenied(perms, requestCode, false);
    }).catch((err: BusinessError) => {
      Log.e(TAG, `showRationaleAndRequest dialog error: ${err?.code}, ${err?.message}`);
    });
  }

  /** 展示"跳转设置"对话框 */
  private showSettingsDialog(config: DialogConfig): void {
    promptAction.showDialog({
      title: config.title,
      message: config.message,
      buttons: [
        { text: config.negativeText, color: '#FF0000' },
        { text: config.positiveText, color: '#007AFF' },
      ]
    }).then(async (dialogResult) => {
      if (dialogResult.index === 1) {
        await this.openAppSettings();
      }
      // 无论确认还是取消，都触发 onSettingsReturned
      this.callbackChannel?.invokeMethod(CALLBACK_ON_SETTINGS_RETURNED, null);
    }).catch((err: BusinessError) => {
      Log.e(TAG, `showSettingsDialog error: ${err?.code}, ${err?.message}`);
    });
  }

  /** 跳转到应用权限设置页 */
  private async openAppSettings(): Promise<void> {
    const context = PermissionUtil.getInstance().getContext();
    const wantInfo: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: { pushParams: context.abilityInfo.bundleName }
    };
    try {
      await context.startAbility(wantInfo);
    } catch (error) {
      const err = error as BusinessError;
      Log.e(TAG, `openAppSettings failed: ${err.code}, ${err.message}`);
    }
  }

  /**
   * 从 MethodCall 参数中解析权限索引数组，转为 ohos 权限名数组
   * Dart 侧传入 int[]（枚举 index），此处按 PermissionOhosList 索引映射
   */
  private resolvePermissionNames(call: MethodCall): string[] {
    const record = call.args as Map<string, Object>;
    const indices = record.get('perms') as number[];
    if (!indices || indices.length === 0) {
      return [];
    }
    return indices.map(index => {
      const idx = Number(index);
      if (idx < 0 || idx >= PermissionOhosList.length) {
        Log.e(TAG, `Invalid permission index: ${index}`);
        return '';
      }
      return PermissionOhosList[idx];
    }).filter(name => name.length > 0);
  }
}

// PermissionCallback 实现：通过 callbackChannel 向 Dart 发送回调
class PermissionCallbackImpl implements PermissionCallback {
  private callbackChannel: MethodChannel;
  private plugin: FlutterEasyPermissionPlugin;

  constructor(channel: MethodChannel, plugin: FlutterEasyPermissionPlugin) {
    this.callbackChannel = channel;
    this.plugin = plugin;
  }

  onPermissionGranted(permissions: Array<Permissions>, requestCode: number): void {
    this.plugin.markGrantedPermissions(permissions);
    const resultMap = new Map<string, Object>();
    resultMap.set('requestCode', requestCode);
    resultMap.set('permsOhos', PermissionCallbackImpl.toIndexArray(permissions));
    Log.i(TAG, `onGranted: requestCode=${requestCode}`);
    this.callbackChannel.invokeMethod(CALLBACK_ON_GRANTED, resultMap);
  }

  onPermissionDenied(permissions: Array<Permissions>, requestCode: number, isPermanent: boolean): void {
    this.plugin.markDeniedPermissions(permissions);
    const resultMap = new Map<string, Object>();
    resultMap.set('requestCode', requestCode);
    resultMap.set('permsOhos', PermissionCallbackImpl.toIndexArray(permissions));
    resultMap.set('permanently', isPermanent);
    Log.i(TAG, `onDenied: requestCode=${requestCode}, isPermanent=${isPermanent}`);
    this.callbackChannel.invokeMethod(CALLBACK_ON_DENIED, resultMap);
  }

  /** 将 Permissions[] 转为 Dart 侧 PermissionsOhos 枚举索引数组 */
  static toIndexArray(permissions: Array<Permissions>): number[] {
    const result: number[] = [];
    for (const perm of permissions) {
      const idx = PermissionOhosList.indexOf(perm.toString());
      if (idx >= 0) {
        result.push(idx);
      }
    }
    return result;
  }
}
