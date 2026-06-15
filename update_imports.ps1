$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File

foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    
    $newContent = $content
    
    # config/
    $newContent = $newContent -replace "package:AroggyaPath/config/", "package:AroggyaPath/core/config/"
    $newContent = $newContent -replace "'config/", "'core/config/"
    $newContent = $newContent -replace "`"config/", "`"core/config/"
    
    # utils/
    $newContent = $newContent -replace "package:AroggyaPath/utils/", "package:AroggyaPath/core/utils/"
    $newContent = $newContent -replace "'utils/", "'core/utils/"
    $newContent = $newContent -replace "`"utils/", "`"core/utils/"
    
    # const.dart
    $newContent = $newContent -replace "package:AroggyaPath/components/const.dart", "package:AroggyaPath/core/constants/app_constants.dart"
    $newContent = $newContent -replace "'components/const.dart'", "'core/constants/app_constants.dart'"
    $newContent = $newContent -replace "`"components/const.dart`"", "`"core/constants/app_constants.dart`""
    
    # components/widgets/
    $newContent = $newContent -replace "package:AroggyaPath/components/widgets/", "package:AroggyaPath/widgets/"
    $newContent = $newContent -replace "'components/widgets/", "'widgets/"
    $newContent = $newContent -replace "`"components/widgets/", "`"widgets/"
    
    # components/
    $newContent = $newContent -replace "package:AroggyaPath/components/", "package:AroggyaPath/widgets/common/"
    $newContent = $newContent -replace "'components/", "'widgets/common/"
    $newContent = $newContent -replace "`"components/", "`"widgets/common/"
    
    # auth screens
    $authScreens = @("login_screen.dart", "signup_screen.dart", "forgatepass_screen.dart", "resetpass_screen.dart", "success_screen.dart", "verify_email.dart")
    foreach ($screen in $authScreens) {
        $newContent = $newContent -replace "package:AroggyaPath/screens/$screen", "package:AroggyaPath/screens/auth/$screen"
        $newContent = $newContent -replace "'screens/$screen'", "'screens/auth/$screen'"
        $newContent = $newContent -replace "`"screens/$screen`"", "`"screens/auth/$screen`""
    }
    
    # profile
    $newContent = $newContent -replace "package:AroggyaPath/profile/user_profile_screen.dart", "package:AroggyaPath/screens/shared/profile/user_profile_screen.dart"
    $newContent = $newContent -replace "'profile/user_profile_screen.dart'", "'screens/shared/profile/user_profile_screen.dart'"
    $newContent = $newContent -replace "`"profile/user_profile_screen.dart`"", "`"screens/shared/profile/user_profile_screen.dart`""
    
    # arogyascreens
    $newContent = $newContent -replace "package:AroggyaPath/arogyascreens/emergency_contact_details_screen.dart", "package:AroggyaPath/screens/patient/emergency/emergency_contact_details_screen.dart"
    $newContent = $newContent -replace "'arogyascreens/emergency_contact_details_screen.dart'", "'screens/patient/emergency/emergency_contact_details_screen.dart'"
    $newContent = $newContent -replace "`"arogyascreens/emergency_contact_details_screen.dart`"", "`"screens/patient/emergency/emergency_contact_details_screen.dart`""
    
    $newContent = $newContent -replace "package:AroggyaPath/arogyascreens/home_screen.dart", "package:AroggyaPath/screens/patient/emergency/emergency_contact_home.dart"
    $newContent = $newContent -replace "'arogyascreens/home_screen.dart'", "'screens/patient/emergency/emergency_contact_home.dart'"
    $newContent = $newContent -replace "`"arogyascreens/home_screen.dart`"", "`"screens/patient/emergency/emergency_contact_home.dart`""
    
    if ($content -cne $newContent) {
        [IO.File]::WriteAllText($f.FullName, $newContent, [System.Text.Encoding]::UTF8)
    }
}
