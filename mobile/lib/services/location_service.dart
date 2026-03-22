import 'package:geolocator/geolocator.dart'; 
 
class LocationService { 
  Future getCurrentPosition() async { 
    return Geolocator.getCurrentPosition(); 
  } 
} 
