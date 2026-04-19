import 'package:flutter/material.dart';

/// Serviço de navegação acessível sem contexto.
///
/// Útil para navegar a partir de services ou camadas
/// que não possuem acesso direto ao BuildContext.
class NavigationService {
  NavigationService._();

  static final NavigationService instance = NavigationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  BuildContext? get context => navigatorKey.currentContext;

  Future<dynamic> pushNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }

  void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop(result);
  }

  Future<dynamic> pushReplacementNamed(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushReplacementNamed(
      routeName,
      arguments: arguments,
    );
  }
}
