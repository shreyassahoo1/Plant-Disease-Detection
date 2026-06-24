import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/locale_provider.dart';

const Map<String, Map<String, String>> _localizedValues = {
  'en': {
    // Navigation & App name
    'Home': 'Home',
    'Sensors': 'Sensors',
    'Rover': 'Rover',
    'Scan': 'Scan',
    'History': 'History',
    'Settings': 'Settings',
    
    // Dashboard / main UI
    'Live Telemetry': 'Live Telemetry',
    'Temperature': 'Temperature',
    'Humidity': 'Humidity',
    'Moisture': 'Moisture',
    'Soil pH': 'Soil pH',
    'Rover Status': 'Rover Status',
    'Connected': 'Connected',
    'Disconnected': 'Disconnected',
    'Battery': 'Battery',
    'Quick Actions': 'Quick Actions',
    'Smart Scan': 'Smart Scan',
    'Manual Control': 'Manual Control',
    'Emergency Stop': 'Emergency Stop',
    'Rover stopped.': 'Rover stopped.',
    'Sector 4 - Active': 'Sector 4 - Active',
    
    // Rover Screen
    'Rover Control': 'Rover Control',
    'Buttons': 'Buttons',
    'Joystick': 'Joystick',
    'Status': 'Status',
    'Start Cam': 'Start Cam',
    'Stop Cam': 'Stop Cam',
    'Auto: ON': 'Auto: ON',
    'Auto: OFF': 'Auto: OFF',
    'Speed': 'Speed',
    'LIVE CAMERA FEED\n(Simulated)': 'LIVE CAMERA FEED\n(Simulated)',
    'Rover Camera Stream\n(Aim at crop)': 'Rover Camera Stream\n(Aim at crop)',
    
    // Settings Screen
    'Appearance': 'Appearance',
    'Dark Theme': 'Dark Theme',
    'Enable futuristic dark mode': 'Enable futuristic dark mode',
    'Connectivity (Mock)': 'Connectivity (Mock)',
    'MQTT Broker URL': 'MQTT Broker URL',
    'FastAPI Endpoint': 'FastAPI Endpoint',
    'Language': 'Language',
    'Select Language': 'Select Language',
    'Choose your preferred language': 'Choose your preferred language',
    
    // History
    'History Logs': 'History Logs',
    'Tomato Late Blight Detected': 'Tomato Late Blight Detected',
    'Healthy Crop Scanned': 'Healthy Crop Scanned',
    'High Temperature Alert': 'High Temperature Alert',
    'Rover Auto-Patrol Completed': 'Rover Auto-Patrol Completed',
    'Wheat Rust Detected': 'Wheat Rust Detected',

    // Motor status
    'IDLE': 'Idle',
    'MOVING_FORWARD': 'Moving Forward',
    'MOVING_BACKWARD': 'Moving Backward',
    'MOVING_LEFT': 'Turning Left',
    'MOVING_RIGHT': 'Turning Right',

    // Sensors Screen
    'Sensor Analytics': 'Sensor Analytics',
    'Real-time Temperature': 'Real-time Temperature',
    'Other Metrics (Mocked History)': 'Other Metrics (Mocked History)',

    // Scan Screen
    'Rover Cam': 'Rover Cam',
    'Retake': 'Retake',
    'Analyze Image': 'Analyze Image',
    'AI is analyzing the scan...': 'AI is analyzing the scan...',
    'Identifying diseases and formulating remedies.': 'Identifying diseases and formulating remedies.',
    'Precautions': 'Precautions',
    'Recommended Indian Fertilizers': 'Recommended Indian Fertilizers',
    'Scan Another Crop': 'Scan Another Crop',
    'Confidence': 'Confidence',
  },
  'hi': {
    // Navigation & App name
    'Home': 'मुख्य',
    'Sensors': 'सेंसर',
    'Rover': 'रोवर',
    'Scan': 'स्कैन',
    'History': 'इतिहास',
    'Settings': 'सेटिंग्स',
    
    // Dashboard / main UI
    'Live Telemetry': 'लाइव टेलीमेट्री',
    'Temperature': 'तापमान',
    'Humidity': 'आर्द्रता',
    'Moisture': 'नमी',
    'Soil pH': 'मिट्टी पीएच',
    'Rover Status': 'रोवर स्थिति',
    'Connected': 'कनेक्टेड',
    'Disconnected': 'डिसकनेक्टेड',
    'Battery': 'बैटरी',
    'Quick Actions': 'त्वरित कार्य',
    'Smart Scan': 'स्मार्ट स्कैन',
    'Manual Control': 'मैनुअल नियंत्रण',
    'Emergency Stop': 'आपातकालीन रोक',
    'Rover stopped.': 'रोवर रोक दिया गया।',
    'Sector 4 - Active': 'सेक्टर 4 - सक्रिय',
    
    // Rover Screen
    'Rover Control': 'रोवर नियंत्रण',
    'Buttons': 'बटन',
    'Joystick': 'जॉयस्टिक',
    'Status': 'स्थिति',
    'Start Cam': 'कैमरा शुरू करें',
    'Stop Cam': 'कैमरा रोकें',
    'Auto: ON': 'ऑटो: चालू',
    'Auto: OFF': 'ऑटो: बंद',
    'Speed': 'गति',
    'LIVE CAMERA FEED\n(Simulated)': 'लाइव कैमरा फीड\n(सिम्युलेटेड)',
    'Rover Camera Stream\n(Aim at crop)': 'रोवर कैमरा स्ट्रीम\n(फसल पर निशाना लगाएं)',
    
    // Settings Screen
    'Appearance': 'सजावट',
    'Dark Theme': 'डार्क थीम',
    'Enable futuristic dark mode': 'भविष्यवादी डार्क मोड सक्षम करें',
    'Connectivity (Mock)': 'कनेक्टिविटी (मॉक)',
    'MQTT Broker URL': 'MQTT ब्रोकर URL',
    'FastAPI Endpoint': 'FastAPI एंडपॉइंट',
    'Language': 'भाषा',
    'Select Language': 'भाषा चुनें',
    'Choose your preferred language': 'अपनी पसंदीदा भाषा चुनें',
    
    // History
    'History Logs': 'इतिहास लॉग',
    'Tomato Late Blight Detected': 'टमाटर लेट ब्लाइट का पता चला',
    'Healthy Crop Scanned': 'स्वस्थ फसल को स्कैन किया गया',
    'High Temperature Alert': 'उच्च तापमान चेतावनी',
    'Rover Auto-Patrol Completed': 'रोवर ऑटो-पैट्रोल पूरा हुआ',
    'Wheat Rust Detected': 'गेहूं के रस्ट का पता चला',

    // Motor status
    'IDLE': 'स्थिर',
    'MOVING_FORWARD': 'आगे बढ़ रहा है',
    'MOVING_BACKWARD': 'पीछे जा रहा है',
    'MOVING_LEFT': 'बाएं मुड़ रहा है',
    'MOVING_RIGHT': 'दाएं मुड़ रहा है',

    // Sensors Screen
    'Sensor Analytics': 'सेंसर विश्लेषण',
    'Real-time Temperature': 'वास्तविक समय तापमान',
    'Other Metrics (Mocked History)': 'अन्य मेट्रिक्स (मॉक इतिहास)',

    // Scan Screen
    'Rover Cam': 'रोवर कैमरा',
    'Retake': 'पुनः लें',
    'Analyze Image': 'छवि का विश्लेषण करें',
    'AI is analyzing the scan...': 'एआई स्कैन का विश्लेषण कर रहा है...',
    'Identifying diseases and formulating remedies.': 'बीमारियों की पहचान और उपचार तैयार किया जा रहा है।',
    'Precautions': 'सावधानियां',
    'Recommended Indian Fertilizers': 'अनुशंसित भारतीय उर्वरक',
    'Scan Another Crop': 'दूसरी फसल स्कैन करें',
    'Confidence': 'विश्वास',
  },
  'te': {
    // Navigation & App name
    'Home': 'హోమ్',
    'Sensors': 'సెన్సార్లు',
    'Rover': 'రోవర్',
    'Scan': 'స్కాన్',
    'History': 'చరిత్ర',
    'Settings': 'సెట్టింగులు',
    
    // Dashboard / main UI
    'Live Telemetry': 'లైవ్ టెలిమెట్రీ',
    'Temperature': 'ఉష్ణోగ్రత',
    'Humidity': 'తేమ',
    'Moisture': 'మట్టి తేమ',
    'Soil pH': 'మట్టి pH',
    'Rover Status': 'రోవర్ స్థితి',
    'Connected': 'కనెక్ట్ అయింది',
    'Disconnected': 'డిస్‌కనెక్ట్ అయింది',
    'Battery': 'బ్యాటరీ',
    'Quick Actions': 'త్వరిత చర్యలు',
    'Smart Scan': 'స్మార్ట్ స్కాన్',
    'Manual Control': 'మాన్యువల్ నియంత్రణ',
    'Emergency Stop': 'అत्यవసర నిలుపుదల',
    'Rover stopped.': 'రోవర్ నిలిపివేయబడింది.',
    'Sector 4 - Active': 'సెక్టార్ 4 - క్రియాశీలం',
    
    // Rover Screen
    'Rover Control': 'రోవర్ నియంత్రణ',
    'Buttons': 'बటన్లు',
    'Joystick': 'జాయ్‌స్టిక్',
    'Status': 'స్థితి',
    'Start Cam': 'కెమెరా ప్రారంభించు',
    'Stop Cam': 'కెమెరా ఆపు',
    'Auto: ON': 'ఆటో: ఆన్',
    'Auto: OFF': 'ఆటో: ఆఫ్',
    'Speed': 'వేగం',
    'LIVE CAMERA FEED\n(Simulated)': 'లైవ్ కెమెరా ఫీడ్\n(సిమ్యులేటెడ్)',
    'Rover Camera Stream\n(Aim at crop)': 'రోవర్ కెమెరా స్ట్రీమ్\n(పంట వైపు చూపండి)',
    
    // Settings Screen
    'Appearance': 'రూపం',
    'Dark Theme': 'డార్క్ థీమ్',
    'Enable futuristic dark mode': 'ಭವಿಷ್ಯತ್ ಡಾರ್ಕ್ ಮೋಡ್ ಅನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ',
    'Connectivity (Mock)': 'కనెక్టివిటీ (మాక్)',
    'MQTT Broker URL': 'MQTT బ్రోకర్ URL',
    'FastAPI Endpoint': 'FastAPI ఎండ్‌పాయింట్',
    'Language': 'భాష',
    'Select Language': 'భాషను ఎంచుకోండి',
    'Choose your preferred language': 'మీకు నచ్చిన భాషను ఎంచుకోండి',
    
    // History
    'History Logs': 'చరిత్ర లాగ్‌లు',
    'Tomato Late Blight Detected': 'టమోటా లేట్ బ్లైట్ కనుగొనబడింది',
    'Healthy Crop Scanned': 'ఆరోగ్యకరమైన పంట స్కాన్ చేయబడింది',
    'High Temperature Alert': 'అధిక ఉష్ణోగ్రత హెచ్చరిక',
    'Rover Auto-Patrol Completed': 'రోవర్ ఆటో-పెట్రోల్ పూర్తయింది',
    'Wheat Rust Detected': 'గోధుమ రస్ట్ కనుగొనబడింది',

    // Motor status
    'IDLE': 'స్థిరంగా ఉంది',
    'MOVING_FORWARD': 'ముందుకు వెళ్తోంది',
    'MOVING_BACKWARD': 'వెనుకకు వెళ్తోంది',
    'MOVING_LEFT': 'ఎడమ వైపు తిరుగుతోంది',
    'MOVING_RIGHT': 'కుడి వైపు తిరుగుతోంది',

    // Sensors Screen
    'Sensor Analytics': 'సెన్సార్ విశ్లేషణ',
    'Real-time Temperature': 'నిజ-సమయ ఉష్ణోగ్రత',
    'Other Metrics (Mocked History)': 'ఇతర కొలతలు (మాక్ చరిత్ర)',

    // Scan Screen
    'Rover Cam': 'రోవర్ కెమెరా',
    'Retake': 'మళ్లీ తీసుకోండి',
    'Analyze Image': 'చిత్రాన్ని విశ్లేషించండి',
    'AI is analyzing the scan...': 'AI స్కాన్‌ను విశ్లేషిస్తోంది...',
    'Identifying diseases and formulating remedies.': 'వ్యాధులను గుర్తించడం మరియు నివారణలను రూపొందించడం.',
    'Precautions': 'జాగ్రత్తలు',
    'Recommended Indian Fertilizers': 'సిఫార్సు చేయబడిన భారతీయ ఎరువులు',
    'Scan Another Crop': 'మరో పంటను స్కాన్ చేయండి',
    'Confidence': 'నమ్మక శాతం',
  },
  'ta': {
    // Navigation & App name
    'Home': 'முகப்பு',
    'Sensors': 'சென்சார்கள்',
    'Rover': 'ரோவர்',
    'Scan': 'ஸ்கேன்',
    'History': 'வரலாறு',
    'Settings': 'அமைப்புகள்',
    
    // Dashboard / main UI
    'Live Telemetry': 'நேரடி அளவீடுகள்',
    'Temperature': 'வெப்பநிலை',
    'Humidity': 'ஈரப்பதம்',
    'Moisture': 'மண் ஈரம்',
    'Soil pH': 'மண் pH',
    'Rover Status': 'ரோவர் நிலை',
    'Connected': 'இணைக்கப்பட்டது',
    'Disconnected': 'துண்டிக்கப்பட்டது',
    'Battery': 'பேட்டரி',
    'Quick Actions': 'விரைவான செயல்கள்',
    'Smart Scan': 'ஸ்மார்ட் ஸ்கேன்',
    'Manual Control': 'கைமுறை கட்டுப்பாடு',
    'Emergency Stop': 'அவசர நிறுத்தம்',
    'Rover stopped.': 'ரோவர் நிறுத்தப்பட்டது.',
    'Sector 4 - Active': 'பிரிவு 4 - செயலில் உள்ளது',
    
    // Rover Screen
    'Rover Control': 'ரோவர் கட்டுப்பாடு',
    'Buttons': 'பொத்தான்கள்',
    'Joystick': 'ஜாய்ஸ்டிக்',
    'Status': 'நிலை',
    'Start Cam': 'கேமராவைத் தொடங்கு',
    'Stop Cam': 'கேமராவை நிறுத்து',
    'Auto: ON': 'தானியங்கி: ஆன்',
    'Auto: OFF': 'தானியங்கி: ஆஃப்',
    'Speed': 'வேகம்',
    'LIVE CAMERA FEED\n(Simulated)': 'நேரடி கேமரா\n(போலி)',
    'Rover Camera Stream\n(Aim at crop)': 'ரோவர் கேமரா\n(பயிரை நோக்கி காட்டவும்)',
    
    // Settings Screen
    'Appearance': 'தோற்றம்',
    'Dark Theme': 'இருண்ட தீம்',
    'Enable futuristic dark mode': 'அதிநவீன இருண்ட பயன்முறையை இயக்கு',
    'Connectivity (Mock)': 'இணைப்பு (போலி)',
    'MQTT Broker URL': 'MQTT தரகர் URL',
    'FastAPI Endpoint': 'FastAPI எண்ட்பாயிண்ட்',
    'Language': 'மொழி',
    'Select Language': 'மொழியைத் தேர்ந்தெடுக்கவும்',
    'Choose your preferred language': 'உங்களுக்கு விருப்பமான மொழியைத் தேர்ந்தெடுக்கவும்',
    
    // History
    'History Logs': 'வரலாற்று பதிவுகள்',
    'Tomato Late Blight Detected': 'தக்காளி நோய் கண்டறியப்பட்டது',
    'Healthy Crop Scanned': 'ஆரோக்கியமான பயிர் ஸ்கேன் செய்யப்பட்டது',
    'High Temperature Alert': 'அதிக வெப்பநிலை எச்சரிக்கை',
    'Rover Auto-Patrol Completed': 'ரோவர் ரோந்து நிறைவடைந்தது',
    'Wheat Rust Detected': 'கோதுமை துரு நோய் கண்டறியப்பட்டது',

    // Motor status
    'IDLE': 'செயலற்றது',
    'MOVING_FORWARD': 'முன்னோக்கி செல்கிறது',
    'MOVING_BACKWARD': 'பின்னோக்கி செல்கிறது',
    'MOVING_LEFT': 'இடது பக்கம் திரும்புகிறது',
    'MOVING_RIGHT': 'வலது பக்கம் திரும்புகிறது',

    // Sensors Screen
    'Sensor Analytics': 'சென்சார் பகுப்பாய்வு',
    'Real-time Temperature': 'உண்மை-நேர வெப்பநிலை',
    'Other Metrics (Mocked History)': 'இதர அளவீடுகள் (போலி வரலாறு)',

    // Scan Screen
    'Rover Cam': 'ரோவர் கேமரா',
    'Retake': 'மீண்டும் எடுக்கவும்',
    'Analyze Image': 'படத்தை பகுப்பாய்வு செய்க',
    'AI is analyzing the scan...': 'AI ஸ்கேனை பகுப்பாய்வு செய்கிறது...',
    'Identifying diseases and formulating remedies.': 'நோய்களைக் கண்டறிந்து தீர்வுகளை உருவாக்குதல்.',
    'Precautions': 'முன்னெச்சரிக்கைகள்',
    'Recommended Indian Fertilizers': 'பரிந்துரைக்கப்பட்ட இந்திய உரங்கள்',
    'Scan Another Crop': 'மற்றொரு பயிரை ஸ்கேன் செய்யவும்',
    'Confidence': 'நம்பகத்தன்மை',
  },
  'kn': {
    // Navigation & App name
    'Home': 'ಹೋಮ್',
    'Sensors': 'ಸಂವೇದಕಗಳು',
    'Rover': 'ರೋವರ್',
    'Scan': 'ಸ್ಕ್ಯಾನ್',
    'History': 'ಇತಿಹಾಸ',
    'Settings': 'ಸೇಟಿಂಗ್ಸ್',
    
    // Dashboard / main UI
    'Live Telemetry': 'ಲೈವ್ ಟೆಲಿಮೆಟ್ರಿ',
    'Temperature': 'ತಾಪಮಾನ',
    'Humidity': 'ಆರ್ದ್ರತೆ',
    'Moisture': 'ಮಣ್ಣಿನ ತೇವಾಂಶ',
    'Soil pH': 'ಮಣ್ಣಿನ pH',
    'Rover Status': 'ರೋವರ್ ಸ್ಥಿತಿ',
    'Connected': 'ಸಂಪರ್ಕಗೊಂಡಿದೆ',
    'Disconnected': 'ಸಂಪರ್ಕ ಕಡಿತಗೊಂಡಿದೆ',
    'Battery': 'ಬ್ಯಾಟರಿ',
    'Quick Actions': 'ತ್ವರಿತ ಕ್ರಮಗಳು',
    'Smart Scan': 'ಸ್ಮಾರ್ಟ್ ಸ್ಕ್ಯಾನ್',
    'Manual Control': 'ಹಸ್ತಚಾಲಿತ ನಿಯಂತ್ರಣ',
    'Emergency Stop': 'ತುರ್ತು ನಿಲುಗಡೆ',
    'Rover stopped.': 'ರೋವರ್ ನಿಲ್ಲಿಸಲಾಗಿದೆ.',
    'Sector 4 - Active': 'ವಲಯ 4 - ಸಕ್ರಿಯ',
    
    // Rover Screen
    'Rover Control': 'ರೋವರ್ ನಿಯಂತ್ರಣ',
    'Buttons': 'ಬಟನ್‌ಗಳು',
    'Joystick': 'ಜಾಯ್‌ಸ್ಟಿಕ್',
    'Status': 'ಸ್ಥಿತಿ',
    'Start Cam': 'ಕ್ಯಾಮೆರಾ ಪ್ರಾರಂಭಿಸಿ',
    'Stop Cam': 'ಕ್ಯಾಮೆರಾ ನಿಲ್ಲಿಸಿ',
    'Auto: ON': 'ಸ್ವಯಂ: ಆನ್',
    'Auto: OFF': 'ಸ್ವಯಂ: ಆಫ್',
    'Speed': 'ವೇಗ',
    'LIVE CAMERA FEED\n(Simulated)': 'ಲೈವ್ ಕ್ಯಾಮೆರಾ ಫೀಡ್\n(ಅನುಕರಿಸಿದ)',
    'Rover Camera Stream\n(Aim at crop)': 'ರೋವರ್ ಕ್ಯಾಮೆರಾ ಸ್ಟ್ರೀಮ್\n(ಬೆಳೆಗೆ ಗುರಿ ಮಾಡಿ)',
    
    // Settings Screen
    'Appearance': 'ನೋಟ',
    'Dark Theme': 'ಕಪ್ಪು ಥೀಮ್',
    'Enable futuristic dark mode': 'ಭವಿಷ್ಯದ ಕಪ್ಪು ಮೋಡ್ ಸಕ್ರಿಯಗೊಳಿಸಿ',
    'Connectivity (Mock)': 'ಸಂಪರ್ಕ (ಮಾಕ್)',
    'MQTT Broker URL': 'MQTT ಬ್ರೋಕರ್ URL',
    'FastAPI Endpoint': 'FastAPI ಎಂಡ್‌ಪಾಯಿಂಟ್',
    'Language': 'ಭಾಷೆ',
    'Select Language': 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    'Choose your preferred language': 'ನಿಮ್ಮ ಆದ್ಯತೆಯ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆಮಾಡಿ',
    
    // History
    'History Logs': 'ಇತಿಹಾಸದ ದಾಖಲೆಗಳು',
    'Tomato Late Blight Detected': 'ಟೊಮೆಟೊ ಲೇಟ್ ಬ್ಲೈಟ್ ಪತ್ತೆಯಾಗಿದೆ',
    'Healthy Crop Scanned': 'ಆರೋಗ್ಯಕರ ಬೆಳೆ ಸ್ಕ್ಯಾನ್ ಮಾಡಲಾಗಿದೆ',
    'High Temperature Alert': 'ಹೆಚ್ಚಿನ ತಾಪಮಾನ ಎಚ್ಚರಿಕೆ',
    'Rover Auto-Patrol Completed': 'ರೋವರ್ ಆಟೋ-ಪೆಟ್ರೋಲ್ ಪೂರ್ಣಗೊಂಡಿದೆ',
    'Wheat Rust Detected': 'ಗೋಧಿ ರಸ್ಟ್ ಪತ್ತೆಯಾಗಿದೆ',

    // Motor status
    'IDLE': 'ಸ್ಥಿರವಾಗಿದೆ',
    'MOVING_FORWARD': 'ಮುಂದಕ್ಕೆ ಚಲಿಸುತ್ತಿದೆ',
    'MOVING_BACKWARD': 'ಹಿಂದಕ್ಕೆ ಚಲಿಸುತ್ತಿದೆ',
    'MOVING_LEFT': 'ಎಡಕ್ಕೆ ತಿರುಗುತ್ತಿದೆ',
    'MOVING_RIGHT': 'ಬಲಕ್ಕೆ ತಿರುಗುತ್ತಿದೆ',

    // Sensors Screen
    'Sensor Analytics': 'ಸಂವೇದಕ ವಿಶ್ಲೇಷಣೆ',
    'Real-time Temperature': 'ನೈಜ-ಸಮಯದ ತಾಪಮಾನ',
    'Other Metrics (Mocked History)': 'ಇತರ ಅಂಕಿಅಂಶಗಳು (ಅನುಕರಿಸಿದ ಇತಿಹಾಸ)',

    // Scan Screen
    'Rover Cam': 'ರೋವರ್ ಕ್ಯಾಮೆರಾ',
    'Retake': 'ಮತ್ತೆ ತೆಗೆಯಿರಿ',
    'Analyze Image': 'ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಿ',
    'AI is analyzing the scan...': 'AI ಸ್ಕ್ಯಾನ್ ಅನ್ನು ವಿಶ್ಲೇಷಿಸುತ್ತಿದೆ...',
    'Identifying diseases and formulating remedies.': 'ರೋಗಗಳನ್ನು ಗುರುತಿಸುವುದು ಮತ್ತು ಪರಿಹಾರಗಳನ್ನು ರೂಪಿಸುವುದು.',
    'Precautions': 'ಮುನ್ನೆಚ್ಚರಿಕೆಗಳು',
    'Recommended Indian Fertilizers': 'ಶಿಫಾರಸು ಮಾಡಲಾದ ಭಾರತೀಯ ರಸಗೊಬ್ಬರಗಳು',
    'Scan Another Crop': 'ಮತ್ತೊಂದು ಬೆಳೆಯನ್ನು ಸ್ಕ್ಯಾನ್ ಮಾಡಿ',
    'Confidence': 'ವಿಶ್ವಾಸಾರ್ಹತೆ',
  }
};

extension TranslateExtension on String {
  String tr(WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;
    return _localizedValues[lang]?[this] ?? this;
  }
}
