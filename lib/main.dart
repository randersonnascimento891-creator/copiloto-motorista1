import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const CopilotApp());
}

class CopilotApp extends StatelessWidget {
  const CopilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Copiloto Motorista Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00FF66),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF66),
          secondary: Color(0xFF1E1E1E),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class RideModel {
  final String pickup;
  final String dropoff;
  final double value;
  final double km;
  final double minutes;
  final bool accepted;

  RideModel({
    required this.pickup,
    required this.dropoff,
    required this.value,
    required this.km,
    required this.minutes,
    required this.accepted,
  });
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<RideModel> _rideHistory = [];

  bool isMonitoring = false;
  bool hasActiveCall = false;
  bool showNotificationBar = false;

  double rideValue = 32.50;
  double rideKm = 7.0;
  double rideMinutes = 20.0;
  String pickupAddress = "Rua das Palmeiras, 450";
  String dropoffAddress = "Av. Paulista, 1000";

  Timer? _simulationTimer;

  void _toggleMonitoring(bool value) {
    setState(() {
      isMonitoring = value;
      if (isMonitoring) {
        _startCallSimulation();
      } else {
        hasActiveCall = false;
        showNotificationBar = false;
        _simulationTimer?.cancel();
      }
    });
  }

  void _startCallSimulation() {
    _simulationTimer = Timer(const Duration(seconds: 4), () {
      if (isMonitoring && mounted) {
        setState(() {
          hasActiveCall = true;
          showNotificationBar = true;
        });
      }
    });
  }

  void _handleRideAction(bool accepted) {
    setState(() {
      _rideHistory.insert(
        0,
        RideModel(
          pickup: pickupAddress,
          dropoff: dropoffAddress,
          value: rideValue,
          km: rideKm,
          minutes: rideMinutes,
          accepted: accepted,
        ),
      );
      hasActiveCall = false;
      if (!accepted) {
        showNotificationBar = false;
      }
    });

    if (accepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrida aceita! Atalhos de navegação disponíveis na barra de notificações.')),
      );
    } else {
      _startCallSimulation();
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      CopilotMonitorTab(
        isMonitoring: isMonitoring,
        hasActiveCall: hasActiveCall,
        showNotificationBar: showNotificationBar,
        rideValue: rideValue,
        rideKm: rideKm,
        rideMinutes: rideMinutes,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        onToggleMonitoring: _toggleMonitoring,
        onAction: _handleRideAction,
        onDismissNotification: () {
          setState(() {
            showNotificationBar = false;
          });
        },
      ),
      RideHistoryTab(history: _rideHistory),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF00FF66),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radar),
            label: 'Copiloto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

class CopilotMonitorTab extends StatelessWidget {
  final bool isMonitoring;
  final bool hasActiveCall;
  final bool showNotificationBar;
  final double rideValue;
  final double rideKm;
  final double rideMinutes;
  final String pickupAddress;
  final String dropoffAddress;
  final Function(bool) onToggleMonitoring;
  final Function(bool) onAction;
  final VoidCallback onDismissNotification;

  const CopilotMonitorTab({
    super.key,
    required this.isMonitoring,
    required this.hasActiveCall,
    required this.showNotificationBar,
    required this.rideValue,
    required this.rideKm,
    required this.rideMinutes,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.onToggleMonitoring,
    required this.onAction,
    required this.onDismissNotification,
  });

  @override
  Widget build(BuildContext context) {
    double valuePerKm = rideKm > 0 ? rideValue / rideKm : 0;
    double valuePerHour = rideMinutes > 0 ? (rideValue / rideMinutes) * 60 : 0;
    bool isLucrative = valuePerKm >= 2.50 && valuePerHour >= 35.0;
    Color indicatorColor = isLucrative ? const Color(0xFF00FF66) : Colors.redAccent;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (showNotificationBar)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF00FF66), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('📱 Notificação Ativa', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        GestureDetector(
                          onTap: onDismissNotification,
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('Embarque: $pickupAddress', style: const TextStyle(fontSize: 13, color: Colors.white)),
                    Text('Destino: $dropoffAddress', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 8)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrindo Waze...')));
                            },
                            icon: const Icon(Icons.navigation, size: 16),
                            label: const Text('Waze', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 8)),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abrindo Google Maps...')));
                            },
                            icon: const Icon(Icons.map, size: 16),
                            label: const Text('Maps', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isMonitoring ? const Color(0xFF00FF66) : Colors.grey),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMonitoring ? 'RADAR LIGADO' : 'RADAR DESLIGADO',
                        style: TextStyle(fontWeight: FontWeight.bold, color: isMonitoring ? const Color(0xFF00FF66) : Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(isMonitoring ? 'Lendo chamadas...' : 'Ligue para iniciar', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                  Switch(
                    value: isMonitoring,
                    activeColor: const Color(0xFF00FF66),
                    onChanged: onToggleMonitoring,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: hasActiveCall
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: indicatorColor, width: 2),
                          boxShadow: [BoxShadow(color: indicatorColor.withOpacity(0.3), blurRadius: 15)],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('⚡ CHAMADA CAPTURADA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(r'R$ ' + rideValue.toStringAsFixed(2), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const Divider(color: Colors.grey, height: 20),
                            Text('📍 $pickupAddress', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text('🏁 $dropoffAddress', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                            const SizedBox(height: 15),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    const Text('VALOR / KM', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(r'R$ ' + valuePerKm.toStringAsFixed(2), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: indicatorColor)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('VALOR / HORA', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text(r'R$ ' + valuePerHour.toStringAsFixed(2), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: indicatorColor)),
                                  ],
                                ),
                                Column(
                                  children: [
                                    const Text('TEMPO/DIST', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    Text('${rideMinutes.toInt()}min / ${rideKm}km', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: indicatorColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                isLucrative ? '✅ CORRIDA LUCRATIVA' : '❌ CORRIDA FRACA',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: indicatorColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                                    onPressed: () => onAction(false),
                                    child: const Text('Recusar', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00FF66), padding: const EdgeInsets.symmetric(vertical: 12)),
                                    onPressed: () => onAction(true),
                                    child: const Text('Aceitar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : const Text(
                        'Aguardando chamadas da Uber/99...\nAtive o radar acima para testar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RideHistoryTab extends StatelessWidget {
  final List<RideModel> history;

  const RideHistoryTab({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Histórico de Corridas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: history.isEmpty
                  ? const Center(child: Text('Nenhuma corrida registrada ainda.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final ride = history[index];
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(
                              ride.accepted ? Icons.check_circle : Icons.cancel,
                              color: ride.accepted ? const Color(0xFF00FF66) : Colors.redAccent,
                            ),
                            title: Text(r'R$ ' + ride.value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('De: ${ride.pickup}\nPara: ${ride.dropoff}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                            trailing: Text('${ride.km} km\n${ride.minutes.toInt()} min', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
