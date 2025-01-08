import 'package:flutter/material.dart';
import 'package:untitled4/components/shared.dart';

class LanguageProvider extends ChangeNotifier {
   String language =
      SharedPrefController().getValueFor<String>(Key: PreKey.language.name) ?? 'en';

  void changeLanguage() {
    language = language == 'en' ? 'ar' : 'en';
    SharedPrefController().setLanguage(language);
    notifyListeners();
  }
}
