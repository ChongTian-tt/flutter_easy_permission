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
import { Permissions } from '@kit.AbilityKit';

// Method Channel 名称
export const CHANNEL_PERMISSIONS = 'xyz.bczl.flutter_easy_permission/permissions';
export const CHANNEL_CALLBACK = 'xyz.bczl.flutter_easy_permission/callback';

// MethodCall 方法名
export const METHOD_HAS_PERMISSIONS = 'hasPermissions';
export const METHOD_REQUEST_PERMISSIONS = 'requestPermissions';
export const METHOD_SHOW_SETTINGS_DIALOG = 'showSettingsDialog';

// Callback 方法名（原生 → Dart）
export const CALLBACK_ON_GRANTED = 'onGranted';
export const CALLBACK_ON_DENIED = 'onDenied';
export const CALLBACK_ON_SETTINGS_RETURNED = 'onSettingsReturned';

// 默认文案
export const DEFAULT_RATIONALE = 'This app may not work correctly without the requested permissions.';
export const DEFAULT_SETTINGS_TITLE = '需要权限';
export const DEFAULT_SETTINGS_RATIONALE = '请前往设置开启权限';
export const DEFAULT_SETTINGS_POSITIVE = '去设置';
export const DEFAULT_SETTINGS_NEGATIVE = '取消';

// HarmonyOS 权限枚举（与 Dart 侧 PermissionsOhos 索引一一对应）
// 注意：系统授权(system_grant)权限安装时自动授予，无需运行时请求，不在此枚举中
export enum PermissionOhos {
  /**
  *  以下为用户授权权限
  *  需要用户同意才能使用，且用户拒绝后无法再次弹出授权框，需引导用户前往设置页手动授权
  *  适用于涉及用户隐私的权限，如日历、健康数据、蓝牙等
  *  开发者应根据应用功能合理申请权限，避免过度申请导致用户反感或拒绝授权
  *  在申请敏感权限时，建议先展示权限说明对话框，向用户解释为何需要该权限以及不授权可能导致的功能受限，以提高授权率
  */
  // 访问蓝牙
  ACCESS_BLUETOOTH = 'ohos.permission.ACCESS_BLUETOOTH',
  // 媒体位置信息
  MEDIA_LOCATION = 'ohos.permission.MEDIA_LOCATION',
  // 允许应用读取开放匿名设备标识符
  APP_TRACKING_CONSENT = 'ohos.permission.APP_TRACKING_CONSENT',
  // 允许应用读取用户的运动状态
  ACTIVITY_MOTION = 'ohos.permission.ACTIVITY_MOTION',
  // 相机权限
  CAMERA = 'ohos.permission.CAMERA',
  // 允许不同设备间的数据交换
  DISTRIBUTED_DATASYNC = 'ohos.permission.DISTRIBUTED_DATASYNC',
  // 允许应用在后台运行时获取设备位置信息
  LOCATION_IN_BACKGROUND = 'ohos.permission.LOCATION_IN_BACKGROUND',
  // 获取设备位置信息
  LOCATION = 'ohos.permission.LOCATION',
  // 设备模糊位置信息
  APPROXIMATELY_LOCATION = 'ohos.permission.APPROXIMATELY_LOCATION',
  // 麦克风权限
  MICROPHONE = 'ohos.permission.MICROPHONE',
  // 读取日历
  READ_CALENDAR = 'ohos.permission.READ_CALENDAR',
  // 写入日历
  WRITE_CALENDAR = 'ohos.permission.WRITE_CALENDAR',
  // 读取健康数据
  READ_HEALTH_DATA = 'ohos.permission.READ_HEALTH_DATA',
  // 允许应用接入星闪并使用星闪能力，例如配对、连接外围设备等
  ACCESS_NEARLINK = 'ohos.permission.ACCESS_NEARLINK',
  // 允许应用访问公共目录下Download目录及子目录
  READ_WRITE_DOWNLOAD_DIRECTORY = 'ohos.permission.READ_WRITE_DOWNLOAD_DIRECTORY',
  // 允许应用访问公共目录下的Documents目录及子目录
  READ_WRITE_DOCUMENTS_DIRECTORY = 'ohos.permission.READ_WRITE_DOCUMENTS_DIRECTORY',
  // 允许应用获取屏幕图像
  CUSTOM_SCREEN_CAPTURE = 'ohos.permission.CUSTOM_SCREEN_CAPTURE', // api 14+支持
  // 读取媒体文件
  READ_MEDIA = 'ohos.permission.READ_MEDIA', // api 22已废弃
  // 写入媒体文件
  WRITE_MEDIA = 'ohos.permission.WRITE_MEDIA', // api 22已废弃
}

/** 索引有序列表，索引位置必须与 Dart 侧 PermissionsOhos 枚举顺序一致 */
export const PermissionOhosList: string[] = [
  // 用户授权权限
  PermissionOhos.ACCESS_BLUETOOTH,
  PermissionOhos.MEDIA_LOCATION,
  PermissionOhos.APP_TRACKING_CONSENT,
  PermissionOhos.ACTIVITY_MOTION,
  PermissionOhos.CAMERA,
  PermissionOhos.DISTRIBUTED_DATASYNC,
  PermissionOhos.LOCATION_IN_BACKGROUND,
  PermissionOhos.LOCATION,
  PermissionOhos.APPROXIMATELY_LOCATION,
  PermissionOhos.MICROPHONE,
  PermissionOhos.READ_CALENDAR,
  PermissionOhos.WRITE_CALENDAR,
  PermissionOhos.READ_HEALTH_DATA,
  PermissionOhos.ACCESS_NEARLINK,
  PermissionOhos.READ_WRITE_DOWNLOAD_DIRECTORY,
  PermissionOhos.READ_WRITE_DOCUMENTS_DIRECTORY,
  PermissionOhos.CUSTOM_SCREEN_CAPTURE,
  PermissionOhos.READ_MEDIA,
  PermissionOhos.WRITE_MEDIA,
];

/** 权限请求结果 */
export interface PermissionResult {
  requestCode: number;
  grantedPermissions: string[];
  deniedPermissions: string[];
}

/** 权限回调接口，由 Plugin 侧实现以接收授权/拒绝通知 */
export interface PermissionCallback {
  onPermissionGranted(permissions: Array<Permissions>, requestCode: number): void;
  onPermissionDenied(permissions: Array<Permissions>, requestCode: number, isPermanent: boolean): void;
}

/** 对话框按钮配置 */
export interface DialogConfig {
  title: string;
  message?: string;
  positiveText: string;
  negativeText: string;
}