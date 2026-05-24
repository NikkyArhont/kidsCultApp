import 'package:flutter_bloc/flutter_bloc.dart';

class CurrentChatCubit extends Cubit<String?> {
  CurrentChatCubit() : super(null);

  void setChat(String id) => emit(id);
  void clearChat() => emit(null);
}
