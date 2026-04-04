import 'package:go_router/go_router.dart';
import 'screens/home.dart';
import 'screens/poi_list.dart';
import 'screens/poi_blog.dart';
import 'screens/admin/login.dart';
import 'screens/admin/poi_add_edit.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Home(
        isAdmin: state.uri.queryParameters['admin'] == 'true',
      ),
    ),
    GoRoute(
      path: '/pois/:areaId',
      builder: (context, state) => PoiList(
        areaId: state.pathParameters['areaId']!,
        isAdmin: state.uri.queryParameters['admin'] == 'true',
      ),
    ),
    GoRoute(
      path: '/pois/:areaId/:poiId',
      builder: (context, state) => PoiBlog(
        areaId: state.pathParameters['areaId']!,
        poiId: state.pathParameters['poiId']!,
        isAdmin: state.uri.queryParameters['admin'] == 'true',
      ),
    ),
    GoRoute(
      path: '/admin/login',
      builder: (context, state) => const Login(),
    ),
    GoRoute(
      path: '/admin/pois/:areaId/add',
      builder: (context, state) => PoiAddEdit(
        areaId: state.pathParameters['areaId']!,
        poi: null, // null = add mode
      ),
    ),
    GoRoute(
      path: '/admin/pois/:areaId/edit/:poiId',
      builder: (context, state) => PoiAddEdit(
        areaId: state.pathParameters['areaId']!,
        poiId: state.pathParameters['poiId'],
        poi: state.extra as Map<String, dynamic>?,
      ),
    ),
  ],
);