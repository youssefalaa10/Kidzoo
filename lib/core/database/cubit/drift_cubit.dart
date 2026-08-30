import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kidzo/core/database/config.dart';

class DriftCubit extends Cubit<AppDatabase> {
  DriftCubit() : super(AppDatabase());
}
