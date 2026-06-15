$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse -File

foreach ($f in $files) {
    $content = Get-Content $f.FullName -Raw
    $newContent = $content
    
    # Replace relative imports with absolute imports using regex
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+config/([^'`"]+)['`"]", "'package:AroggyaPath/core/config/`$2'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+utils/([^'`"]+)['`"]", "'package:AroggyaPath/core/utils/`$2'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+const.dart['`"]", "'package:AroggyaPath/core/constants/app_constants.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+components/const.dart['`"]", "'package:AroggyaPath/core/constants/app_constants.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+components/custom_([^'`"]+)['`"]", "'package:AroggyaPath/widgets/common/custom_`$2'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+components/widgets/([^'`"]+)['`"]", "'package:AroggyaPath/widgets/`$2'")
    
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+profile/user_profile_screen.dart['`"]", "'package:AroggyaPath/screens/shared/profile/user_profile_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+arogyascreens/([^'`"]+)['`"]", "'package:AroggyaPath/screens/patient/emergency/`$2'")
    $newContent = [regex]::Replace($newContent, "emergency/home_screen.dart", "emergency/emergency_contact_home.dart")
    
    # Also relative auth screens
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+login_screen.dart['`"]", "'package:AroggyaPath/screens/auth/login_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+signup_screen.dart['`"]", "'package:AroggyaPath/screens/auth/signup_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+forgatepass_screen.dart['`"]", "'package:AroggyaPath/screens/auth/forgatepass_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+resetpass_screen.dart['`"]", "'package:AroggyaPath/screens/auth/resetpass_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+success_screen.dart['`"]", "'package:AroggyaPath/screens/auth/success_screen.dart'")
    $newContent = [regex]::Replace($newContent, "['`"](\.\./)+verify_email.dart['`"]", "'package:AroggyaPath/screens/auth/verify_email.dart'")

    # Same dir auth screens (if they used 'login_screen.dart' directly in screens folder)
    # Wait, they are now in auth. But let's leave same dir imports for auth screens alone or fix them if they fail later.

    if ($content -cne $newContent) {
        [IO.File]::WriteAllText($f.FullName, $newContent, [System.Text.Encoding]::UTF8)
    }
}
