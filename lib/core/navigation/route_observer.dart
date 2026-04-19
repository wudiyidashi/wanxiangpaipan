import 'package:flutter/widgets.dart';

/// 全局路由观察者
///
/// 用于让依赖历史记录 / 全局状态的页面（首页、历史列表）在**任何**
/// `Navigator.push` 之后被 `pop` 回来时收到 `didPopNext` 回调，从而主动
/// 刷新数据。具体原因：
///
/// - 起课流程目前使用 `Navigator.push(castScreen)` → 结果页 → `pop` 回首页
/// - 期间保存新记录后，首页 State 不会重新 `initState`，脏数据会留在屏幕
/// - 用 `RouteObserver` + `RouteAware` 可以零侵入地在返回时触发刷新，
///   比给每个起课入口绑 `.then()` 回调更通用、更易扩展
///
/// 注册位置：`MaterialApp.navigatorObservers`
/// 订阅位置：`State.didChangeDependencies` / 取消在 `dispose`
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
