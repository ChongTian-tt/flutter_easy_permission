
const DefaultRequestCode = 101;

///
/// AppSettingsDialog的默认文本内容
///
const SettingsDialogTitle = "需要的权限";
const SettingsDialogRationale = "如果没有所请求的权限，此应用可能无法正常工作，请打开应用设置界面，修改应用权限。";
const SettingsDialogPositiveButton = "确定";
const SettingsDialogNegativeButton = "取消";

enum Permissions {
  WRITE_CONTACTS,
  GET_ACCOUNTS,
  READ_CONTACTS,
  READ_CALL_LOG,
  READ_PHONE_STATE,
  CALL_PHONE,
  WRITE_CALL_LOG,
  USE_SIP,
  PROCESS_OUTGOING_CALLS,
  ADD_VOICEMAIL,
  READ_CALENDAR,
  WRITE_CALENDAR,
  CAMERA,
  BODY_SENSORS,
  ACCESS_FINE_LOCATION,
  ACCESS_COARSE_LOCATION,
  READ_EXTERNAL_STORAGE,
  WRITE_EXTERNAL_STORAGE,
  RECORD_AUDIO,
  READ_SMS,
  RECEIVE_WAP_PUSH,
  RECEIVE_MMS,
  RECEIVE_SMS,
  SEND_SMS,
}

// *****************************************************************************
// ************************************ iOS ************************************
// *****************************************************************************
enum PermissionGroup {
  Location,
  Camera,
  Photos,
  Contacts,
  Reminders,
  Calendar,
  Microphone,
  Health,
  DataNetwork,
  MediaLibrary,
  Tracking,
  Notification,
  Bluetooth
}

// *****************************************************************************
// ************************************ ohos ************************************
// *****************************************************************************
// 注意：系统授权(system_grant)权限安装时自动授予，无需运行时请求，不在此枚举中
// 索引顺序必须与 ohos 侧 PermissionOhosList 一一对应
enum PermissionsOhos {
  // 用户授权权限（user_grant）19个
  ACCESS_BLUETOOTH, // 访问蓝牙
  MEDIA_LOCATION, // 媒体位置信息
  APP_TRACKING_CONSENT, // 应用追踪
  ACTIVITY_MOTION, // 运动状态
  CAMERA, // 相机
  DISTRIBUTED_DATASYNC, // 分布式数据同步
  LOCATION_IN_BACKGROUND, // 后台定位
  LOCATION, // 定位
  APPROXIMATELY_LOCATION, // 模糊定位
  MICROPHONE, // 麦克风
  READ_CALENDAR, // 读取日历
  WRITE_CALENDAR, // 写入日历
  READ_HEALTH_DATA, // 健康数据
  ACCESS_NEARLINK, // 星闪
  READ_WRITE_DOWNLOAD_DIRECTORY, // 访问Download目录
  READ_WRITE_DOCUMENTS_DIRECTORY, // 访问Documents目录
  CUSTOM_SCREEN_CAPTURE, // 屏幕截图 api 14开始支持
  READ_MEDIA, // 读取媒体文件 api 22 已废弃
  WRITE_MEDIA, // 写入媒体文件 api 22 已废弃
}

