import 'package:get_storage/get_storage.dart';


class MemoryService {
  static final MemoryService _mInstance = MemoryService._();

  static MemoryService get instance => _mInstance;

  late GetStorage _storage;

  MemoryService._() {
    _storage = GetStorage('uae-pass-app');
  }

  Future initialize() async {
    await GetStorage.init('uae-pass-app');
  }



  String? get accessCode => _storage.read("accessCode");
  set accessCode(String? value) => _storage.write("accessCode", value);


}
