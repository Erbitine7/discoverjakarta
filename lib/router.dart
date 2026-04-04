import 'package:go_router/go_router.dart';

import 'auth/auth_notifier.dart';
import 'screens/admin/login.dart';
import 'screens/admin/poi_add_edit.dart';
import 'screens/home.dart';
import 'screens/poi_blog.dart';
import 'screens/poi_list.dart';

GoRouter createAppRouter(AuthNotifier auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (path.startsWith('/admin/pois') && !auth.isLoggedIn) {
        return '/admin/login';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Home(
          isAdmin: auth.isLoggedIn,
          auth: auth,
        ),
      ),
      GoRoute(
        path: '/pois/:areaId',
        builder: (context, state) => PoiList(
          auth: auth,
          areaId: state.pathParameters['areaId']!,
          isAdmin: auth.isLoggedIn,
        ),
      ),
      GoRoute(
        path: '/pois/:areaId/:poiId',
        builder: (context, state) => PoiBlog(
          areaId: state.pathParameters['areaId']!,
          poiId: state.pathParameters['poiId']!,
          isAdmin: auth.isLoggedIn,
        ),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => Login(auth: auth),
      ),
      GoRoute(
        path: '/admin/pois/:areaId/add',
        builder: (context, state) => PoiAddEdit(
          auth: auth,
          areaId: state.pathParameters['areaId']!,
        ),
      ),
      GoRoute(
        path: '/admin/pois/:areaId/edit/:poiId',
        builder: (context, state) => PoiAddEdit(
          auth: auth,
          areaId: state.pathParameters['areaId']!,
          poiId: state.pathParameters['poiId']!,
        ),
      ),
    ],
  );
}
