class AppRoutes {
  // Public and authentication routes
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Organizer management routes
  static const String organizer = '/organizer';
  static const String organizerCreateExhibition = '/organizer/create-exhibition';
  static const String organizerBoothPackages = '/organizer/booth-packages';
  static const String organizerBoothSpots = '/organizer/booth-spots';
  static const String organizerExhibitionDetails = '/organizer/exhibition-details';

  // Exhibitor browsing and application routes
  static const String exhibitionDetails = '/exhibition-details';
  static const String selectBooth = '/select-booth';
  static const String applicationForm = '/application-form';
  static const String boothApplicationFlow = '/booth-application-flow';
  static const String applicationDetails = '/application-details';
  static const String notifications = '/notifications';

  // Admin management routes
  static const String admin = '/admin';
  static const String adminUserDetails = '/admin/user-details';
  static const String adminCreateExhibition = '/admin/create-exhibition';
  static const String adminExhibitionDetails = '/admin/exhibition-details';
  static const String adminBoothPackages = '/admin/booth-packages';
  static const String adminBoothSpots = '/admin/booth-spots';

  // Profile route
  static const String personalInformation = '/profile/personal-information';
}