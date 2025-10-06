import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/user_provider.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/custom_text_field.dart';
import '../widgets/common/error_widget.dart';
import '../widgets/common/loading_overlay.dart';
import '../constants/app_constants.dart';
import 'goals_selection_screen.dart';

class CountrySelectionScreen extends ConsumerStatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  ConsumerState<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends ConsumerState<CountrySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCountry;
  bool _isDetectingLocation = false;

  final List<Map<String, String>> _countries = [
    {'name': 'Afghanistan', 'code': 'AF', 'flag': '🇦🇫'},
    {'name': 'Albania', 'code': 'AL', 'flag': '🇦🇱'},
    {'name': 'Algeria', 'code': 'DZ', 'flag': '🇩🇿'},
    {'name': 'Andorra', 'code': 'AD', 'flag': '🇦🇩'},
    {'name': 'Angola', 'code': 'AO', 'flag': '🇦🇴'},
    {'name': 'Antigua and Barbuda', 'code': 'AG', 'flag': '🇦🇬'},
    {'name': 'Argentina', 'code': 'AR', 'flag': '🇦🇷'},
    {'name': 'Armenia', 'code': 'AM', 'flag': '🇦🇲'},
    {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
    {'name': 'Austria', 'code': 'AT', 'flag': '🇦🇹'},
    {'name': 'Azerbaijan', 'code': 'AZ', 'flag': '🇦🇿'},
    {'name': 'Bahamas', 'code': 'BS', 'flag': '🇧🇸'},
    {'name': 'Bahrain', 'code': 'BH', 'flag': '🇧🇭'},
    {'name': 'Bangladesh', 'code': 'BD', 'flag': '🇧🇩'},
    {'name': 'Barbados', 'code': 'BB', 'flag': '🇧🇧'},
    {'name': 'Belarus', 'code': 'BY', 'flag': '🇧🇾'},
    {'name': 'Belgium', 'code': 'BE', 'flag': '🇧🇪'},
    {'name': 'Belize', 'code': 'BZ', 'flag': '🇧🇿'},
    {'name': 'Benin', 'code': 'BJ', 'flag': '🇧🇯'},
    {'name': 'Bhutan', 'code': 'BT', 'flag': '🇧🇹'},
    {'name': 'Bolivia', 'code': 'BO', 'flag': '🇧🇴'},
    {'name': 'Bosnia and Herzegovina', 'code': 'BA', 'flag': '🇧🇦'},
    {'name': 'Botswana', 'code': 'BW', 'flag': '🇧🇼'},
    {'name': 'Brazil', 'code': 'BR', 'flag': '🇧🇷'},
    {'name': 'Brunei', 'code': 'BN', 'flag': '🇧🇳'},
    {'name': 'Bulgaria', 'code': 'BG', 'flag': '🇧🇬'},
    {'name': 'Burkina Faso', 'code': 'BF', 'flag': '🇧🇫'},
    {'name': 'Burundi', 'code': 'BI', 'flag': '🇧🇮'},
    {'name': 'Cambodia', 'code': 'KH', 'flag': '🇰🇭'},
    {'name': 'Cameroon', 'code': 'CM', 'flag': '🇨🇲'},
    {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
    {'name': 'Cape Verde', 'code': 'CV', 'flag': '🇨🇻'},
    {'name': 'Central African Republic', 'code': 'CF', 'flag': '🇨🇫'},
    {'name': 'Chad', 'code': 'TD', 'flag': '🇹🇩'},
    {'name': 'Chile', 'code': 'CL', 'flag': '🇨🇱'},
    {'name': 'China', 'code': 'CN', 'flag': '🇨🇳'},
    {'name': 'Colombia', 'code': 'CO', 'flag': '🇨🇴'},
    {'name': 'Comoros', 'code': 'KM', 'flag': '🇰🇲'},
    {'name': 'Congo', 'code': 'CG', 'flag': '🇨🇬'},
    {'name': 'Costa Rica', 'code': 'CR', 'flag': '🇨🇷'},
    {'name': 'Croatia', 'code': 'HR', 'flag': '🇭🇷'},
    {'name': 'Cuba', 'code': 'CU', 'flag': '🇨🇺'},
    {'name': 'Cyprus', 'code': 'CY', 'flag': '🇨🇾'},
    {'name': 'Czech Republic', 'code': 'CZ', 'flag': '🇨🇿'},
    {'name': 'Democratic Republic of the Congo', 'code': 'CD', 'flag': '🇨🇩'},
    {'name': 'Denmark', 'code': 'DK', 'flag': '🇩🇰'},
    {'name': 'Djibouti', 'code': 'DJ', 'flag': '🇩🇯'},
    {'name': 'Dominica', 'code': 'DM', 'flag': '🇩🇲'},
    {'name': 'Dominican Republic', 'code': 'DO', 'flag': '🇩🇴'},
    {'name': 'East Timor', 'code': 'TL', 'flag': '🇹🇱'},
    {'name': 'Ecuador', 'code': 'EC', 'flag': '🇪🇨'},
    {'name': 'Egypt', 'code': 'EG', 'flag': '🇪🇬'},
    {'name': 'El Salvador', 'code': 'SV', 'flag': '🇸🇻'},
    {'name': 'Equatorial Guinea', 'code': 'GQ', 'flag': '🇬🇶'},
    {'name': 'Eritrea', 'code': 'ER', 'flag': '🇪🇷'},
    {'name': 'Estonia', 'code': 'EE', 'flag': '🇪🇪'},
    {'name': 'Eswatini', 'code': 'SZ', 'flag': '🇸🇿'},
    {'name': 'Ethiopia', 'code': 'ET', 'flag': '🇪🇹'},
    {'name': 'Fiji', 'code': 'FJ', 'flag': '🇫🇯'},
    {'name': 'Finland', 'code': 'FI', 'flag': '🇫🇮'},
    {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
    {'name': 'Gabon', 'code': 'GA', 'flag': '🇬🇦'},
    {'name': 'Gambia', 'code': 'GM', 'flag': '🇬🇲'},
    {'name': 'Georgia', 'code': 'GE', 'flag': '🇬🇪'},
    {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
    {'name': 'Ghana', 'code': 'GH', 'flag': '🇬🇭'},
    {'name': 'Greece', 'code': 'GR', 'flag': '🇬🇷'},
    {'name': 'Grenada', 'code': 'GD', 'flag': '🇬🇩'},
    {'name': 'Guatemala', 'code': 'GT', 'flag': '🇬🇹'},
    {'name': 'Guinea', 'code': 'GN', 'flag': '🇬🇳'},
    {'name': 'Guinea-Bissau', 'code': 'GW', 'flag': '🇬🇼'},
    {'name': 'Guyana', 'code': 'GY', 'flag': '🇬🇾'},
    {'name': 'Haiti', 'code': 'HT', 'flag': '🇭🇹'},
    {'name': 'Honduras', 'code': 'HN', 'flag': '🇭🇳'},
    {'name': 'Hungary', 'code': 'HU', 'flag': '🇭🇺'},
    {'name': 'Iceland', 'code': 'IS', 'flag': '🇮🇸'},
    {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
    {'name': 'Indonesia', 'code': 'ID', 'flag': '🇮🇩'},
    {'name': 'Iran', 'code': 'IR', 'flag': '🇮🇷'},
    {'name': 'Iraq', 'code': 'IQ', 'flag': '🇮🇶'},
    {'name': 'Ireland', 'code': 'IE', 'flag': '🇮🇪'},
    {'name': 'Israel', 'code': 'IL', 'flag': '🇮🇱'},
    {'name': 'Italy', 'code': 'IT', 'flag': '🇮🇹'},
    {'name': 'Ivory Coast', 'code': 'CI', 'flag': '🇨🇮'},
    {'name': 'Jamaica', 'code': 'JM', 'flag': '🇯🇲'},
    {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
    {'name': 'Jordan', 'code': 'JO', 'flag': '🇯🇴'},
    {'name': 'Kazakhstan', 'code': 'KZ', 'flag': '🇰🇿'},
    {'name': 'Kenya', 'code': 'KE', 'flag': '🇰🇪'},
    {'name': 'Kiribati', 'code': 'KI', 'flag': '🇰🇮'},
    {'name': 'Kuwait', 'code': 'KW', 'flag': '🇰🇼'},
    {'name': 'Kyrgyzstan', 'code': 'KG', 'flag': '🇰🇬'},
    {'name': 'Laos', 'code': 'LA', 'flag': '🇱🇦'},
    {'name': 'Latvia', 'code': 'LV', 'flag': '🇱🇻'},
    {'name': 'Lebanon', 'code': 'LB', 'flag': '🇱🇧'},
    {'name': 'Lesotho', 'code': 'LS', 'flag': '🇱🇸'},
    {'name': 'Liberia', 'code': 'LR', 'flag': '🇱🇷'},
    {'name': 'Libya', 'code': 'LY', 'flag': '🇱🇾'},
    {'name': 'Liechtenstein', 'code': 'LI', 'flag': '🇱🇮'},
    {'name': 'Lithuania', 'code': 'LT', 'flag': '🇱🇹'},
    {'name': 'Luxembourg', 'code': 'LU', 'flag': '🇱🇺'},
    {'name': 'Madagascar', 'code': 'MG', 'flag': '🇲🇬'},
    {'name': 'Malawi', 'code': 'MW', 'flag': '🇲🇼'},
    {'name': 'Malaysia', 'code': 'MY', 'flag': '🇲🇾'},
    {'name': 'Maldives', 'code': 'MV', 'flag': '🇲🇻'},
    {'name': 'Mali', 'code': 'ML', 'flag': '🇲🇱'},
    {'name': 'Malta', 'code': 'MT', 'flag': '🇲🇹'},
    {'name': 'Marshall Islands', 'code': 'MH', 'flag': '🇲🇭'},
    {'name': 'Mauritania', 'code': 'MR', 'flag': '🇲🇷'},
    {'name': 'Mauritius', 'code': 'MU', 'flag': '🇲🇺'},
    {'name': 'Mexico', 'code': 'MX', 'flag': '🇲🇽'},
    {'name': 'Micronesia', 'code': 'FM', 'flag': '🇫🇲'},
    {'name': 'Moldova', 'code': 'MD', 'flag': '🇲🇩'},
    {'name': 'Monaco', 'code': 'MC', 'flag': '🇲🇨'},
    {'name': 'Mongolia', 'code': 'MN', 'flag': '🇲🇳'},
    {'name': 'Montenegro', 'code': 'ME', 'flag': '🇲🇪'},
    {'name': 'Morocco', 'code': 'MA', 'flag': '🇲🇦'},
    {'name': 'Mozambique', 'code': 'MZ', 'flag': '🇲🇿'},
    {'name': 'Myanmar', 'code': 'MM', 'flag': '🇲🇲'},
    {'name': 'Namibia', 'code': 'NA', 'flag': '🇳🇦'},
    {'name': 'Nauru', 'code': 'NR', 'flag': '🇳🇷'},
    {'name': 'Nepal', 'code': 'NP', 'flag': '🇳🇵'},
    {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
    {'name': 'New Zealand', 'code': 'NZ', 'flag': '🇳🇿'},
    {'name': 'Nicaragua', 'code': 'NI', 'flag': '🇳🇮'},
    {'name': 'Niger', 'code': 'NE', 'flag': '🇳🇪'},
    {'name': 'Nigeria', 'code': 'NG', 'flag': '🇳🇬'},
    {'name': 'North Korea', 'code': 'KP', 'flag': '🇰🇵'},
    {'name': 'North Macedonia', 'code': 'MK', 'flag': '🇲🇰'},
    {'name': 'Norway', 'code': 'NO', 'flag': '🇳🇴'},
    {'name': 'Oman', 'code': 'OM', 'flag': '🇴🇲'},
    {'name': 'Pakistan', 'code': 'PK', 'flag': '🇵🇰'},
    {'name': 'Palau', 'code': 'PW', 'flag': '🇵🇼'},
    {'name': 'Panama', 'code': 'PA', 'flag': '🇵🇦'},
    {'name': 'Papua New Guinea', 'code': 'PG', 'flag': '🇵🇬'},
    {'name': 'Paraguay', 'code': 'PY', 'flag': '🇵🇾'},
    {'name': 'Peru', 'code': 'PE', 'flag': '🇵🇪'},
    {'name': 'Philippines', 'code': 'PH', 'flag': '🇵🇭'},
    {'name': 'Poland', 'code': 'PL', 'flag': '🇵🇱'},
    {'name': 'Portugal', 'code': 'PT', 'flag': '🇵🇹'},
    {'name': 'Qatar', 'code': 'QA', 'flag': '🇶🇦'},
    {'name': 'Romania', 'code': 'RO', 'flag': '🇷🇴'},
    {'name': 'Russia', 'code': 'RU', 'flag': '🇷🇺'},
    {'name': 'Rwanda', 'code': 'RW', 'flag': '🇷🇼'},
    {'name': 'Saint Kitts and Nevis', 'code': 'KN', 'flag': '🇰🇳'},
    {'name': 'Saint Lucia', 'code': 'LC', 'flag': '🇱🇨'},
    {'name': 'Saint Vincent and the Grenadines', 'code': 'VC', 'flag': '🇻🇨'},
    {'name': 'Samoa', 'code': 'WS', 'flag': '🇼🇸'},
    {'name': 'San Marino', 'code': 'SM', 'flag': '🇸🇲'},
    {'name': 'Sao Tome and Principe', 'code': 'ST', 'flag': '🇸🇹'},
    {'name': 'Saudi Arabia', 'code': 'SA', 'flag': '🇸🇦'},
    {'name': 'Senegal', 'code': 'SN', 'flag': '🇸🇳'},
    {'name': 'Serbia', 'code': 'RS', 'flag': '🇷🇸'},
    {'name': 'Seychelles', 'code': 'SC', 'flag': '🇸🇨'},
    {'name': 'Sierra Leone', 'code': 'SL', 'flag': '🇸🇱'},
    {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
    {'name': 'Slovakia', 'code': 'SK', 'flag': '🇸🇰'},
    {'name': 'Slovenia', 'code': 'SI', 'flag': '🇸🇮'},
    {'name': 'Solomon Islands', 'code': 'SB', 'flag': '🇸🇧'},
    {'name': 'Somalia', 'code': 'SO', 'flag': '🇸🇴'},
    {'name': 'South Africa', 'code': 'ZA', 'flag': '🇿🇦'},
    {'name': 'South Korea', 'code': 'KR', 'flag': '🇰🇷'},
    {'name': 'South Sudan', 'code': 'SS', 'flag': '🇸🇸'},
    {'name': 'Spain', 'code': 'ES', 'flag': '🇪🇸'},
    {'name': 'Sri Lanka', 'code': 'LK', 'flag': '🇱🇰'},
    {'name': 'Sudan', 'code': 'SD', 'flag': '🇸🇩'},
    {'name': 'Suriname', 'code': 'SR', 'flag': '🇸🇷'},
    {'name': 'Sweden', 'code': 'SE', 'flag': '🇸🇪'},
    {'name': 'Switzerland', 'code': 'CH', 'flag': '🇨🇭'},
    {'name': 'Syria', 'code': 'SY', 'flag': '🇸🇾'},
    {'name': 'Taiwan', 'code': 'TW', 'flag': '🇹🇼'},
    {'name': 'Tajikistan', 'code': 'TJ', 'flag': '🇹🇯'},
    {'name': 'Tanzania', 'code': 'TZ', 'flag': '🇹🇿'},
    {'name': 'Thailand', 'code': 'TH', 'flag': '🇹🇭'},
    {'name': 'Togo', 'code': 'TG', 'flag': '🇹🇬'},
    {'name': 'Tonga', 'code': 'TO', 'flag': '🇹🇴'},
    {'name': 'Trinidad and Tobago', 'code': 'TT', 'flag': '🇹🇹'},
    {'name': 'Tunisia', 'code': 'TN', 'flag': '🇹🇳'},
    {'name': 'Turkey', 'code': 'TR', 'flag': '🇹🇷'},
    {'name': 'Turkmenistan', 'code': 'TM', 'flag': '🇹🇲'},
    {'name': 'Tuvalu', 'code': 'TV', 'flag': '🇹🇻'},
    {'name': 'Uganda', 'code': 'UG', 'flag': '🇺🇬'},
    {'name': 'Ukraine', 'code': 'UA', 'flag': '🇺🇦'},
    {'name': 'United Arab Emirates', 'code': 'AE', 'flag': '🇦🇪'},
    {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
    {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
    {'name': 'Uruguay', 'code': 'UY', 'flag': '🇺🇾'},
    {'name': 'Uzbekistan', 'code': 'UZ', 'flag': '🇺🇿'},
    {'name': 'Vanuatu', 'code': 'VU', 'flag': '🇻🇺'},
    {'name': 'Vatican City', 'code': 'VA', 'flag': '🇻🇦'},
    {'name': 'Venezuela', 'code': 'VE', 'flag': '🇻🇪'},
    {'name': 'Vietnam', 'code': 'VN', 'flag': '🇻🇳'},
    {'name': 'Yemen', 'code': 'YE', 'flag': '🇾🇪'},
    {'name': 'Zambia', 'code': 'ZM', 'flag': '🇿🇲'},
    {'name': 'Zimbabwe', 'code': 'ZW', 'flag': '🇿🇼'},
  ];

  List<Map<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _countries;
    _searchController.addListener(_filterCountries);
  }

  void _filterCountries() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredCountries = _countries;
      } else {
        _filteredCountries = _countries.where((country) {
          return country['name']!.toLowerCase().contains(_searchController.text.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location detection timed out');
        },
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Geocoding timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        String countryName = placemarks.first.country ?? '';
        if (countryName.isNotEmpty) {
          setState(() {
            _selectedCountry = countryName;
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Detected location: $countryName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not determine country from location'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not determine country from location'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } on TimeoutException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location detection timed out. Please try again or select manually.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error detecting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  Future<void> _saveCountrySelection() async {
    if (_selectedCountry == null) return;

    await ref.read(userNotifierProvider.notifier).updateCountry(_selectedCountry!);
    
    // Listen to the update result
    ref.listen(userNotifierProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const GoalsSelectionScreen(),
              ),
            );
          }
        },
        error: (error, stack) {
          if (mounted) {
            ErrorSnackBar.show(context, 'Failed to save country selection');
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userUpdateState = ref.watch(userNotifierProvider);
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: LoadingOverlay(
        isLoading: userUpdateState.isLoading,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLarge),
                child: Column(
                  children: [
                    const SizedBox(height: AppConstants.spacingXXLarge),
                    Text(
                      'Specify your location',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeTitle,
                        fontWeight: AppConstants.fontWeightBold,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingSmall),
                    Text(
                      'Select your country or determine location automatically',
                      style: GoogleFonts.poppins(
                        fontSize: AppConstants.fontSizeLarge,
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.spacingXLarge),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingSmall),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[300],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingXLarge),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _searchController,
                            hintText: 'Search countries...',
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingMedium),
                        CustomButton(
                          text: _isDetectingLocation ? 'Detecting...' : 'Current Location',
                          icon: _isDetectingLocation ? null : Icons.my_location,
                          onPressed: _isDetectingLocation ? null : _detectLocation,
                          isLoading: _isDetectingLocation,
                          height: AppConstants.buttonHeightLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = _filteredCountries[index];
                    final isSelected = _selectedCountry == country['name'];
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacingLarge, 
                        vertical: AppConstants.spacingSmall,
                      ),
                      leading: Text(
                        country['flag']!,
                        style: const TextStyle(fontSize: AppConstants.iconSizeLarge),
                      ),
                      title: Text(
                        country['name']!,
                        style: GoogleFonts.poppins(
                          fontSize: AppConstants.fontSizeLarge,
                          fontWeight: isSelected ? AppConstants.fontWeightSemiBold : AppConstants.fontWeightNormal,
                          color: isSelected ? AppConstants.primaryColor : AppConstants.textPrimary,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppConstants.primaryColor,
                              size: AppConstants.iconSizeLarge,
                            )
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCountry = country['name'];
                        });
                      },
                    );
                  },
                ),
              ),
              if (_selectedCountry != null)
                Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingLarge),
                  child: CustomButton(
                    text: 'Continue',
                    onPressed: userUpdateState.isLoading ? null : _saveCountrySelection,
                    isLoading: userUpdateState.isLoading,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 