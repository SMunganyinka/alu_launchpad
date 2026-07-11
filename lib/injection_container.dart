import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Features
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/sign_in_usecase.dart';
import 'features/auth/domain/usecases/sign_up_usecase.dart';
import 'features/auth/auth_bloc.dart';
import 'features/opportunity/opportunity_bloc.dart';
import 'features/bookmark/bookmark_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // --- External ---
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);

  // --- Auth Feature ---
  sl.registerLazySingleton<AuthRemoteDatasource>(
    () => AuthRemoteDatasourceImpl(firebaseAuth: sl(), firestore: sl()),
  );

  sl.registerLazySingleton<AuthRepositoryImpl>(
    () => AuthRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => SignInUseCase(sl()));
  sl.registerLazySingleton(() => SignUpUseCase(sl()));

  // --- BLoCs / Cubits ---
  sl.registerFactory(
    () => AuthBloc(
      signInUseCase: sl(),
      signUpUseCase: sl(),
      repository: sl(),
    ),
  );

  sl.registerFactory(
    () => OpportunityBloc(),
  );

  // BookmarkCubit registered as a Factory with a fallback empty string
  // so it doesn't crash the app if opened before a user logs in
  sl.registerFactory(
    () => BookmarkCubit(sl(), FirebaseAuth.instance.currentUser?.uid ?? ''),
  );
}
