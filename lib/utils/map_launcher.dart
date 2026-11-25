import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  static Future<void> showAppChooser({
    required BuildContext context,
    required double lat,
    required double lng,
    required String nombreLugar,
  }) async {
    // 1. Verificamos si la app de Uber está instalada
    final uberUri = Uri.parse(
      'uber://?action=setPickup&pickup=my_location&dropoff[latitude]=$lat&dropoff[longitude]=$lng&dropoff[nickname]=$nombreLugar',
    );
    final canLaunchUber = await canLaunchUrl(uberUri);

    // 2. Verificamos si la app de DiDi está instalada
    final didiUri = Uri.parse('didiglobal://?lat=$lat&lng=$lng&name=$nombreLugar');
    final canLaunchDidi = await canLaunchUrl(didiUri);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E2235),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  '¿Cómo querés llegar?',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Opción Google Maps (o el mapa por defecto)
              ListTile(
                leading: const Icon(Icons.map, color: Colors.green),
                title: const Text('Abrir con la app de Mapas', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Google Maps, Waze, etc.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context); // Cerramos el diálogo
                  
                  // Formato estándar de Android: geo:lat,lng?q=lat,lng
                  final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
                  
                  if (await canLaunchUrl(geoUri)) {
                    // IMPORTANTE: SIN LaunchMode.externalApplication para que muestre el menú
                    await launchUrl(geoUri); 
                  } else {
                    // Si falla, abrimos Google Maps en el navegador
                    final fallbackUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                    if (await canLaunchUrl(fallbackUri)) {
                      await launchUrl(fallbackUri);
                    }
                  }
                },
              ),
              // Opción Uber
              if (canLaunchUber)
                ListTile(
                  leading: const Icon(Icons.local_taxi, color: Colors.white),
                  title: const Text('Pedir un Uber', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(uberUri, mode: LaunchMode.externalApplication);
                  },
                ),
              // Opción DiDi
              if (canLaunchDidi)
                ListTile(
                  leading: const Icon(Icons.local_taxi, color: Colors.orangeAccent),
                  title: const Text('Pedir un DiDi', style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    await launchUrl(didiUri, mode: LaunchMode.externalApplication);
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
