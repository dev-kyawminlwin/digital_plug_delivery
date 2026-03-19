import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_my.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
    Locale('my'),
    Locale('th'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Digital Plug Delivery'**
  String get appTitle;

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeScreenTitle;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search restaurants or dishes...'**
  String get searchPlaces;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @meals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get meals;

  /// No description provided for @fastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast Food'**
  String get fastFood;

  /// No description provided for @coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get coffee;

  /// No description provided for @desserts.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get desserts;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// No description provided for @featuredShops.
  ///
  /// In en, this message translates to:
  /// **'Featured Shops'**
  String get featuredShops;

  /// No description provided for @popularNearYou.
  ///
  /// In en, this message translates to:
  /// **'Popular Near You'**
  String get popularNearYou;

  /// No description provided for @min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get min;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @shop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @ratings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get ratings;

  /// No description provided for @ledger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledger;

  /// No description provided for @fleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get fleet;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @deliveringTo.
  ///
  /// In en, this message translates to:
  /// **'Delivering to'**
  String get deliveringTo;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// No description provided for @findFood.
  ///
  /// In en, this message translates to:
  /// **'Find food or restaurant...'**
  String get findFood;

  /// No description provided for @popularRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Popular Restaurants'**
  String get popularRestaurants;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @heroText.
  ///
  /// In en, this message translates to:
  /// **'Get Your\nFavorite Meals\nDelivered\nToday!'**
  String get heroText;

  /// No description provided for @catMain.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get catMain;

  /// No description provided for @catSoups.
  ///
  /// In en, this message translates to:
  /// **'Soups'**
  String get catSoups;

  /// No description provided for @catSalads.
  ///
  /// In en, this message translates to:
  /// **'Salads'**
  String get catSalads;

  /// No description provided for @catDrinks.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get catDrinks;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Fastest operation to provide food\nby the fence.'**
  String get appTagline;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginBtn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyAccount;

  /// No description provided for @skipGuest.
  ///
  /// In en, this message translates to:
  /// **'Skip & Continue as Guest'**
  String get skipGuest;

  /// No description provided for @createAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get createAnAccount;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role'**
  String get selectYourRole;

  /// No description provided for @roleCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get roleCustomer;

  /// No description provided for @roleShopOwner.
  ///
  /// In en, this message translates to:
  /// **'Shop Owner'**
  String get roleShopOwner;

  /// No description provided for @roleRider.
  ///
  /// In en, this message translates to:
  /// **'Rider'**
  String get roleRider;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account with your email and password.'**
  String get loginSubtitle;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @saveMe.
  ///
  /// In en, this message translates to:
  /// **'Save me'**
  String get saveMe;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields.'**
  String get fillAllFields;

  /// No description provided for @customerLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customerLabel;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your personal details to get started.'**
  String get createAccountSubtitle;

  /// No description provided for @fullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneHint;

  /// No description provided for @deliveryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address (optional)'**
  String get deliveryAddressHint;

  /// No description provided for @emailAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressHint;

  /// No description provided for @shopOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Shop Owner'**
  String get shopOwnerLabel;

  /// No description provided for @openShop.
  ///
  /// In en, this message translates to:
  /// **'Open Shop'**
  String get openShop;

  /// No description provided for @openShopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Register your business to start delivering items.'**
  String get openShopSubtitle;

  /// No description provided for @shopNameHint.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopNameHint;

  /// No description provided for @ownerFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Owner Full Name'**
  String get ownerFullNameHint;

  /// No description provided for @shopAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Shop Address'**
  String get shopAddressHint;

  /// No description provided for @alreadyPartner.
  ///
  /// In en, this message translates to:
  /// **'Already a partner? '**
  String get alreadyPartner;

  /// No description provided for @fleetRider.
  ///
  /// In en, this message translates to:
  /// **'Fleet Rider'**
  String get fleetRider;

  /// No description provided for @becomeRider.
  ///
  /// In en, this message translates to:
  /// **'Become a Rider'**
  String get becomeRider;

  /// No description provided for @becomeRiderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join our fleet and start earning today.'**
  String get becomeRiderSubtitle;

  /// No description provided for @homeAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddressHint;

  /// No description provided for @alreadyRider.
  ///
  /// In en, this message translates to:
  /// **'Already a rider? '**
  String get alreadyRider;

  /// No description provided for @tachileikDelivery.
  ///
  /// In en, this message translates to:
  /// **'Tachileik Delivery'**
  String get tachileikDelivery;

  /// No description provided for @tabOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get tabOrders;

  /// No description provided for @tabShop.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get tabShop;

  /// No description provided for @tabMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get tabMenu;

  /// No description provided for @tabRatings.
  ///
  /// In en, this message translates to:
  /// **'Ratings'**
  String get tabRatings;

  /// No description provided for @tabLedger.
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get tabLedger;

  /// No description provided for @tabFleet.
  ///
  /// In en, this message translates to:
  /// **'Fleet'**
  String get tabFleet;

  /// No description provided for @liveOrders.
  ///
  /// In en, this message translates to:
  /// **'Live Orders'**
  String get liveOrders;

  /// No description provided for @myShop.
  ///
  /// In en, this message translates to:
  /// **'My Shop'**
  String get myShop;

  /// No description provided for @menuManager.
  ///
  /// In en, this message translates to:
  /// **'Menu Manager'**
  String get menuManager;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get noOrdersYet;

  /// No description provided for @addItemsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Start adding items to your menu to drive sales!'**
  String get addItemsPrompt;

  /// No description provided for @goToMenuManager.
  ///
  /// In en, this message translates to:
  /// **'Go to Menu Manager'**
  String get goToMenuManager;

  /// No description provided for @grossRevenue.
  ///
  /// In en, this message translates to:
  /// **'Gross Revenue'**
  String get grossRevenue;

  /// No description provided for @riderPayout.
  ///
  /// In en, this message translates to:
  /// **'Rider Payout'**
  String get riderPayout;

  /// No description provided for @netEarnings.
  ///
  /// In en, this message translates to:
  /// **'Net Earnings'**
  String get netEarnings;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @noRiderYet.
  ///
  /// In en, this message translates to:
  /// **'No Rider Yet'**
  String get noRiderYet;

  /// No description provided for @riderPanel.
  ///
  /// In en, this message translates to:
  /// **'RIDER PANEL'**
  String get riderPanel;

  /// No description provided for @online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @cashToDrop.
  ///
  /// In en, this message translates to:
  /// **'Cash to Drop'**
  String get cashToDrop;

  /// No description provided for @myOrders.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// No description provided for @radar.
  ///
  /// In en, this message translates to:
  /// **'Radar'**
  String get radar;

  /// No description provided for @fleetMap.
  ///
  /// In en, this message translates to:
  /// **'Fleet Map'**
  String get fleetMap;

  /// No description provided for @activeDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Active Deliveries'**
  String get activeDeliveries;

  /// No description provided for @settleBalances.
  ///
  /// In en, this message translates to:
  /// **'Settle Balances with Shop'**
  String get settleBalances;

  /// No description provided for @balancesSettled.
  ///
  /// In en, this message translates to:
  /// **'Balances settled ✓'**
  String get balancesSettled;

  /// No description provided for @noActiveDeliveries.
  ///
  /// In en, this message translates to:
  /// **'No active deliveries. Check the Radar! 📡'**
  String get noActiveDeliveries;

  /// No description provided for @allQuiet.
  ///
  /// In en, this message translates to:
  /// **'All quiet! No new orders right now. 🛋️'**
  String get allQuiet;

  /// No description provided for @newOrder.
  ///
  /// In en, this message translates to:
  /// **'NEW ORDER'**
  String get newOrder;

  /// No description provided for @acceptOrder.
  ///
  /// In en, this message translates to:
  /// **'⚡ ACCEPT ORDER'**
  String get acceptOrder;

  /// No description provided for @orderAccepted.
  ///
  /// In en, this message translates to:
  /// **'✅ Order accepted! Check My Orders.'**
  String get orderAccepted;

  /// No description provided for @orderTakenByRider.
  ///
  /// In en, this message translates to:
  /// **'⚡ Too slow! Another rider claimed it.'**
  String get orderTakenByRider;

  /// No description provided for @pickUp.
  ///
  /// In en, this message translates to:
  /// **'PICK UP'**
  String get pickUp;

  /// No description provided for @iveArrived.
  ///
  /// In en, this message translates to:
  /// **'I\'VE ARRIVED'**
  String get iveArrived;

  /// No description provided for @completeDelivery.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE ✓'**
  String get completeDelivery;

  /// No description provided for @cancelBtn.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelBtn;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logOut;

  /// No description provided for @hiGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi'**
  String get hiGreeting;

  /// No description provided for @whatToDo.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do?'**
  String get whatToDo;
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
      <String>['en', 'my', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'my':
      return AppLocalizationsMy();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
