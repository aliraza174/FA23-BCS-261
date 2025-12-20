import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/image_picker_util.dart';
import '../error/failures.dart';
import '../../features/admin/data/repositories/menu_repository_impl.dart';
import '../../features/admin/domain/repositories/menu_repository.dart';
import '../../features/admin/data/repositories/deals_repository_impl.dart';
import '../../features/admin/domain/repositories/deals_repository.dart';
import '../../features/admin/data/repositories/ai_training_repository_impl.dart';
import '../../features/admin/domain/repositories/ai_training_repository.dart';
import '../../features/admin/data/repositories/restaurant_repository_impl.dart';
import '../../features/admin/domain/repositories/restaurant_repository.dart';
import '../../features/admin/domain/usecases/menu/get_categories.dart';
import '../../features/admin/domain/usecases/menu/create_category.dart';
import '../../features/admin/domain/usecases/menu/update_category.dart';
import '../../features/admin/domain/usecases/menu/delete_category.dart';
import '../../features/admin/domain/usecases/food_item/get_food_items.dart';
import '../../features/admin/domain/usecases/food_item/get_food_items_by_category.dart';
import '../../features/admin/domain/usecases/food_item/create_food_item.dart';
import '../../features/admin/domain/usecases/food_item/update_food_item.dart';
import '../../features/admin/domain/usecases/food_item/delete_food_item.dart';
import '../../features/admin/domain/usecases/deals/get_deals.dart';
import '../../features/admin/domain/usecases/deals/create_deal.dart';
import '../../features/admin/domain/usecases/deals/update_deal.dart';
import '../../features/admin/domain/usecases/deals/delete_deal.dart';
import '../../features/admin/domain/usecases/ai_data/get_ai_data.dart';
import '../../features/admin/domain/usecases/ai_data/create_ai_data.dart';
import '../../features/admin/domain/usecases/ai_data/update_ai_data.dart';
import '../../features/admin/domain/usecases/ai_data/delete_ai_data.dart';
import '../../features/admin/domain/usecases/restaurant/get_restaurants.dart';
import '../../features/admin/domain/usecases/restaurant/create_restaurant.dart';
import '../../features/admin/domain/usecases/restaurant/update_restaurant.dart';
import '../../features/admin/domain/usecases/restaurant/delete_restaurant.dart';
import '../../features/admin/presentation/bloc/menu_bloc.dart';
import '../../features/admin/presentation/bloc/food_item/food_item_bloc.dart';
import '../../features/admin/presentation/bloc/deal/deal_bloc.dart';
import '../../features/admin/presentation/bloc/ai_data/ai_data_bloc.dart';
import '../../features/admin/presentation/bloc/restaurant/restaurant_bloc.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/models/admin_model.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/get_current_admin.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

final getIt = GetIt.instance;

// Simple auth datasource that uses SupabaseClient directly
class AuthRemoteDataSourceImplSimple implements AuthRemoteDataSource {
  final SupabaseClient _client;

  AuthRemoteDataSourceImplSimple(this._client);

  @override
  Future<AdminModel> signIn(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthException('Invalid credentials');
      }

      final adminData = await _client
          .from('admins')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AdminModel(
        id: adminData['id'] as String,
        role: adminData['role'] as String,
        createdAt: DateTime.parse(adminData['created_at'] as String),
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<AdminModel?> getCurrentAdmin() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      final adminData = await _client
          .from('admins')
          .select()
          .eq('id', user.id)
          .single();

      return AdminModel(
        id: adminData['id'] as String,
        role: adminData['role'] as String,
        createdAt: DateTime.parse(adminData['created_at'] as String),
      );
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      final adminData = await _client
          .from('admins')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      return adminData != null;
    } catch (e) {
      return false;
    }
  }
}

Future<void> initDependencies() async {
  // Core
  final supabase = Supabase.instance.client;
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);
  
  // Register the SupabaseClient directly for the auth datasource
  // Since SupabaseClientWrapper needs initialization, let's use a direct approach

  // Utils
  getIt.registerLazySingleton(() => ImagePickerUtil(getIt()));

  // Features - Auth
  // Data sources - using SupabaseClient directly
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImplSimple(getIt<SupabaseClient>()),
  );
  
  // Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt()),
  );

  // Use cases
  getIt.registerLazySingleton(() => SignIn(getIt()));
  getIt.registerLazySingleton(() => GetCurrentAdmin(getIt()));

  // Features - Menu
  // Repository
  getIt.registerLazySingleton<MenuRepository>(
    () => MenuRepositoryImpl(getIt()),
  );

  // Features - Deals
  // Repository
  getIt.registerLazySingleton<DealsRepository>(
    () => DealsRepositoryImpl(getIt()),
  );

  // Features - AI Data
  // Repository
  getIt.registerLazySingleton<AiTrainingRepository>(
    () => AiTrainingRepositoryImpl(getIt()),
  );

  // Features - Restaurant
  // Repository
  getIt.registerLazySingleton<RestaurantRepository>(
    () => RestaurantRepositoryImpl(getIt()),
  );


  // Use cases - Menu Categories
  getIt.registerLazySingleton(() => GetCategories(getIt()));
  getIt.registerLazySingleton(() => CreateCategory(getIt()));
  getIt.registerLazySingleton(() => UpdateCategory(getIt()));
  getIt.registerLazySingleton(() => DeleteCategory(getIt()));

  // Use cases - Food Items
  getIt.registerLazySingleton(() => GetFoodItems(getIt()));
  getIt.registerLazySingleton(() => GetFoodItemsByCategory(getIt()));
  getIt.registerLazySingleton(() => CreateFoodItem(getIt()));
  getIt.registerLazySingleton(() => UpdateFoodItem(getIt()));
  getIt.registerLazySingleton(() => DeleteFoodItem(getIt()));

  // Use cases - Deals
  getIt.registerLazySingleton(() => GetDeals(getIt()));
  getIt.registerLazySingleton(() => CreateDeal(getIt()));
  getIt.registerLazySingleton(() => UpdateDeal(getIt()));
  getIt.registerLazySingleton(() => DeleteDeal(getIt()));

  // Use cases - AI Data
  getIt.registerLazySingleton(() => GetAiData(getIt()));
  getIt.registerLazySingleton(() => CreateAiData(getIt()));
  getIt.registerLazySingleton(() => UpdateAiData(getIt()));
  getIt.registerLazySingleton(() => DeleteAiData(getIt()));

  // Use cases - Restaurant
  getIt.registerLazySingleton(() => GetRestaurants(getIt()));
  getIt.registerLazySingleton(() => CreateRestaurant(getIt()));
  getIt.registerLazySingleton(() => UpdateRestaurant(getIt()));
  getIt.registerLazySingleton(() => DeleteRestaurant(getIt()));

  // Blocs
  getIt.registerFactory(
    () => AuthBloc(
      signIn: getIt(),
      getCurrentAdmin: getIt(),
    ),
  );

  getIt.registerFactory(
    () => MenuBloc(
      getCategories: getIt(),
      createCategory: getIt(),
      updateCategory: getIt(),
      deleteCategory: getIt(),
    ),
  );

  getIt.registerFactory(
    () => FoodItemBloc(
      getFoodItems: getIt(),
      getFoodItemsByCategory: getIt(),
      createFoodItem: getIt(),
      updateFoodItem: getIt(),
      deleteFoodItem: getIt(),
    ),
  );

  getIt.registerFactory(
    () => DealBloc(
      getDeals: getIt(),
      createDeal: getIt(),
      updateDeal: getIt(),
      deleteDeal: getIt(),
    ),
  );

  getIt.registerFactory(
    () => AiDataBloc(
      getAiData: getIt(),
      createAiData: getIt(),
      updateAiData: getIt(),
      deleteAiData: getIt(),
    ),
  );

  getIt.registerFactory(
    () => RestaurantBloc(
      getRestaurants: getIt(),
      createRestaurant: getIt(),
      updateRestaurant: getIt(),
      deleteRestaurant: getIt(),
    ),
  );
}
