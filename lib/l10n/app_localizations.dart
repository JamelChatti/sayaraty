import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Sayaraty'**
  String get appTitle;

  /// No description provided for @vehicles.
  ///
  /// In en, this message translates to:
  /// **'Vehicles'**
  String get vehicles;

  /// No description provided for @addVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add a vehicle'**
  String get addVehicle;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @missingData.
  ///
  /// In en, this message translates to:
  /// **'Missing data'**
  String get missingData;

  /// No description provided for @invalidData.
  ///
  /// In en, this message translates to:
  /// **'Invalid data'**
  String get invalidData;

  /// No description provided for @vehicleNotFound.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get vehicleNotFound;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @companyHome.
  ///
  /// In en, this message translates to:
  /// **'Company Home'**
  String get companyHome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @noAccountCreate.
  ///
  /// In en, this message translates to:
  /// **'No account? Create one'**
  String get noAccountCreate;

  /// No description provided for @ownerHome.
  ///
  /// In en, this message translates to:
  /// **'Owner Home'**
  String get ownerHome;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get welcome;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role:'**
  String get role;

  /// No description provided for @proHome.
  ///
  /// In en, this message translates to:
  /// **'Professional Home'**
  String get proHome;

  /// No description provided for @pro.
  ///
  /// In en, this message translates to:
  /// **'Pro:'**
  String get pro;

  /// No description provided for @passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsMismatch;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get createAccount;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get accountType;

  /// No description provided for @individual.
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// No description provided for @companyAdmin.
  ///
  /// In en, this message translates to:
  /// **'Company (Admin)'**
  String get companyAdmin;

  /// No description provided for @professionalGarage.
  ///
  /// In en, this message translates to:
  /// **'Professional (Garage)'**
  String get professionalGarage;

  /// No description provided for @oilFilter.
  ///
  /// In en, this message translates to:
  /// **'Oil filter'**
  String get oilFilter;

  /// No description provided for @airFilter.
  ///
  /// In en, this message translates to:
  /// **'Air filter'**
  String get airFilter;

  /// No description provided for @cabinFilter.
  ///
  /// In en, this message translates to:
  /// **'Cabin filter'**
  String get cabinFilter;

  /// No description provided for @fuelFilter.
  ///
  /// In en, this message translates to:
  /// **'Fuel filter'**
  String get fuelFilter;

  /// No description provided for @engineOil.
  ///
  /// In en, this message translates to:
  /// **'Engine oil'**
  String get engineOil;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @newIntervention.
  ///
  /// In en, this message translates to:
  /// **'New service'**
  String get newIntervention;

  /// No description provided for @interventionTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Service type *'**
  String get interventionTypeRequired;

  /// No description provided for @replacedParts.
  ///
  /// In en, this message translates to:
  /// **'Replaced parts'**
  String get replacedParts;

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleRequired;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get requiredField;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @dateRequired.
  ///
  /// In en, this message translates to:
  /// **'Date *'**
  String get dateRequired;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @mileageRequired.
  ///
  /// In en, this message translates to:
  /// **'Mileage *'**
  String get mileageRequired;

  /// No description provided for @invalidMileage.
  ///
  /// In en, this message translates to:
  /// **'Invalid mileage'**
  String get invalidMileage;

  /// No description provided for @nextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get nextDue;

  /// No description provided for @km.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get km;

  /// No description provided for @garageName.
  ///
  /// In en, this message translates to:
  /// **'Garage name'**
  String get garageName;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact (phone/email)'**
  String get contact;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCost;

  /// No description provided for @invalidCost.
  ///
  /// In en, this message translates to:
  /// **'Invalid cost'**
  String get invalidCost;

  /// No description provided for @interventionSaved.
  ///
  /// In en, this message translates to:
  /// **'Service saved!'**
  String get interventionSaved;

  /// No description provided for @oilChange.
  ///
  /// In en, this message translates to:
  /// **'Oil change'**
  String get oilChange;

  /// No description provided for @brakes.
  ///
  /// In en, this message translates to:
  /// **'Brakes'**
  String get brakes;

  /// No description provided for @tires.
  ///
  /// In en, this message translates to:
  /// **'Tires'**
  String get tires;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @belt.
  ///
  /// In en, this message translates to:
  /// **'Belt'**
  String get belt;

  /// No description provided for @technicalInspection.
  ///
  /// In en, this message translates to:
  /// **'Technical inspection'**
  String get technicalInspection;

  /// No description provided for @repair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repair;

  /// No description provided for @brandOptional.
  ///
  /// In en, this message translates to:
  /// **'Brand (optional)'**
  String get brandOptional;

  /// No description provided for @detail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price (€)'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Qty'**
  String get quantity;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @noIntervention.
  ///
  /// In en, this message translates to:
  /// **'No service'**
  String get noIntervention;

  /// No description provided for @addFirstIntervention.
  ///
  /// In en, this message translates to:
  /// **'Add your first oil change, repair or inspection.'**
  String get addFirstIntervention;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete?'**
  String get deleteConfirm;

  /// No description provided for @deleteInterventionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this service?'**
  String get deleteInterventionConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @interventionDeleted.
  ///
  /// In en, this message translates to:
  /// **'Service deleted'**
  String get interventionDeleted;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusDone;

  /// No description provided for @statusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get statusPlanned;

  /// No description provided for @statusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get statusCanceled;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed (reload required)'**
  String get languageChanged;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @vehicleAdded.
  ///
  /// In en, this message translates to:
  /// **'Vehicle added!'**
  String get vehicleAdded;

  /// No description provided for @editVehicle.
  ///
  /// In en, this message translates to:
  /// **'Edit vehicle'**
  String get editVehicle;

  /// No description provided for @deleteVehicleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this vehicle?'**
  String get deleteVehicleConfirm;

  /// No description provided for @vehicleUpdated.
  ///
  /// In en, this message translates to:
  /// **'Vehicle updated'**
  String get vehicleUpdated;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF document'**
  String get pdfDocument;

  /// No description provided for @vehicleImage.
  ///
  /// In en, this message translates to:
  /// **'Vehicle image'**
  String get vehicleImage;

  /// No description provided for @vehicleImageApp.
  ///
  /// In en, this message translates to:
  /// **'Vehicle image - Sayaraty'**
  String get vehicleImageApp;

  /// No description provided for @shareError.
  ///
  /// In en, this message translates to:
  /// **'Error while sharing'**
  String get shareError;

  /// No description provided for @clientVehicles.
  ///
  /// In en, this message translates to:
  /// **'Client vehicles'**
  String get clientVehicles;

  /// No description provided for @noSharedVehicle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle shared with you'**
  String get noSharedVehicle;

  /// No description provided for @unknownPlate.
  ///
  /// In en, this message translates to:
  /// **'Unknown plate'**
  String get unknownPlate;

  /// No description provided for @shareVehicle.
  ///
  /// In en, this message translates to:
  /// **'Share vehicle'**
  String get shareVehicle;

  /// No description provided for @selectAuthorizedPro.
  ///
  /// In en, this message translates to:
  /// **'Select an authorized professional:'**
  String get selectAuthorizedPro;

  /// No description provided for @sharedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Shared successfully!'**
  String get sharedSuccess;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @plateNumber.
  ///
  /// In en, this message translates to:
  /// **'Plate number'**
  String get plateNumber;

  /// No description provided for @year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get year;

  /// No description provided for @vin.
  ///
  /// In en, this message translates to:
  /// **'VIN'**
  String get vin;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @shareWithPro.
  ///
  /// In en, this message translates to:
  /// **'Share with a pro'**
  String get shareWithPro;

  /// No description provided for @mainPhoto.
  ///
  /// In en, this message translates to:
  /// **'Main photo'**
  String get mainPhoto;

  /// No description provided for @imageSelected.
  ///
  /// In en, this message translates to:
  /// **'Image selected successfully!'**
  String get imageSelected;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @deleteVehicle.
  ///
  /// In en, this message translates to:
  /// **'Delete this vehicle?'**
  String get deleteVehicle;

  /// No description provided for @deleteVehicleWarning.
  ///
  /// In en, this message translates to:
  /// **'All related services will also be deleted.'**
  String get deleteVehicleWarning;

  /// No description provided for @vehicleDeleted.
  ///
  /// In en, this message translates to:
  /// **'Vehicle deleted'**
  String get vehicleDeleted;

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Sayaraty'**
  String get appName;

  /// No description provided for @noVehicle.
  ///
  /// In en, this message translates to:
  /// **'No vehicle'**
  String get noVehicle;

  /// No description provided for @addFirstVehicle.
  ///
  /// In en, this message translates to:
  /// **'Add your first vehicle to start tracking its maintenance.'**
  String get addFirstVehicle;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get viewDetails;

  /// No description provided for @vehicleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Vehicle not found'**
  String get vehicleUnavailable;

  /// No description provided for @max.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get max;

  /// No description provided for @files.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get files;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file exceeds 10 MB and was ignored'**
  String get fileTooLarge;

  /// No description provided for @cannotOpenPdf.
  ///
  /// In en, this message translates to:
  /// **'Unable to open PDF'**
  String get cannotOpenPdf;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @extensionNotDetected.
  ///
  /// In en, this message translates to:
  /// **'Extension not detected'**
  String get extensionNotDetected;

  /// No description provided for @addFiles.
  ///
  /// In en, this message translates to:
  /// **'Add files'**
  String get addFiles;

  /// No description provided for @searchBrand.
  ///
  /// In en, this message translates to:
  /// **'Search for a brand...'**
  String get searchBrand;

  /// No description provided for @brandRequired.
  ///
  /// In en, this message translates to:
  /// **'Brand *'**
  String get brandRequired;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required field'**
  String get required;

  /// No description provided for @undefined.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get undefined;

  /// No description provided for @yearRequired.
  ///
  /// In en, this message translates to:
  /// **'Year *'**
  String get yearRequired;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Invalid year'**
  String get invalidYear;

  /// No description provided for @incorrectYear.
  ///
  /// In en, this message translates to:
  /// **'Incorrect year'**
  String get incorrectYear;

  /// No description provided for @mileageKm.
  ///
  /// In en, this message translates to:
  /// **'Mileage (km)'**
  String get mileageKm;

  /// No description provided for @insuranceExpiry.
  ///
  /// In en, this message translates to:
  /// **'Insurance expiry'**
  String get insuranceExpiry;

  /// No description provided for @taxExpiry.
  ///
  /// In en, this message translates to:
  /// **'Tax expiry'**
  String get taxExpiry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
