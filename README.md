# FogCast Mobile App

Dieses Git-Repository enthält die mobile Anwendung **FogCast**, welche als Ergänzung zum bestehenden FogCast-System entwickelt wurde. Die App ermöglicht den mobilen Zugriff auf aktuelle Wetterdaten, Wettervorhersagen sowie historische Wasserstandsdaten und stellt diese in einer benutzerfreundlichen Oberfläche dar.

Die Anwendung richtet sich sowohl an Nutzerinnen und Nutzer, die einen schnellen Überblick über die aktuelle Wetterlage erhalten möchten, als auch an Anwender mit erweitertem Informationsbedarf. Hierfür stehen ein **Basic-Modus** mit den wichtigsten Wetterinformationen sowie ein **Expertenmodus** mit zusätzlichen meteorologischen Parametern und interaktiven Diagrammen zur Verfügung.

Neben dem Quellcode der mobilen Anwendung enthält dieses Repository ebenfalls die Projektdokumentation und die technische Dokumentation der App.

---

## 📂 Repository-Inhalt

Das Repository gliedert sich in folgende Bereiche:

```text
FogCast_App/
│
├── android/                 # Android-spezifische Projektdateien
├── ios/                     # iOS-spezifische Projektdateien
├── lib/                     # Quellcode der Flutter-Anwendung
│   ├── api/                 # Kommunikation mit dem Backend
│   ├── data/                # DTOs und Datenmodelle
│   ├── repository/          # Datenzugriff und Verarbeitung
│   ├── state/               # Riverpod State Management
│   ├── pages/               # Benutzeroberflächen
│   ├── widgets/             # Wiederverwendbare UI-Komponenten
│   └── main.dart            # Einstiegspunkt der Anwendung
│
├── documentation/
│   ├── Projektdokumentation.pdf
│   └── Technische_Dokumentation.pdf
│
├── test/                    # Unit-Tests
├── pubspec.yaml             # Projekt- und Paketkonfiguration
└── README.md
```

---

## 🛠️ Implementierung

Die mobile Anwendung wurde mit **Flutter** entwickelt und ermöglicht dadurch eine plattformübergreifende Ausführung auf Android- und iOS-Geräten. Der Zugriff auf Wetterdaten erfolgt über die bereits vorhandenen REST-Schnittstellen des FogCast-Backends. Die App verarbeitet aktuelle Wetterdaten, Wettervorhersagen sowie historische Messwerte und visualisiert diese in einer für mobile Endgeräte optimierten Benutzeroberfläche.

Die Software wurde modular aufgebaut:
* Die Kommunikation mit dem Backend erfolgt über eigene **API-Klassen**.
* **Repositories** kapseln den gezielten Datenzugriff.
* Das **State Management** wird mithilfe von Riverpod umgesetzt, wodurch Daten zentral verwaltet und automatisch an die Benutzeroberfläche weitergegeben werden können.

---
## 📲 Installation (für Nutzerinnen und Nutzer)

Wenn Sie die FogCast-App auf Ihrem Android-Gerät installieren möchten, ohne den Quellcode zu kompilieren, können Sie die bereitgestellte APK-Datei nutzen:

1. **APK herunterladen:** Navigieren Sie zu den [GitHub Releases](https://github.com/FogCast-Konstanz/FogCast-App/releases) dieses Repositories und laden Sie die aktuelle `.apk`-Datei herunter.
2. **Unbekannte Quellen erlauben:** Da die App außerhalb des Google Play Stores bereitgestellt wird, müssen Sie auf Ihrem Smartphone einmalig die Installation von Apps aus unbekannten Quellen in Ihren Systemeinstellungen erlauben.
3. **Installieren:** Öffnen Sie die heruntergeladene APK-Datei auf Ihrem Gerät und folgen Sie den Installationsanweisungen.

evtl. muss der Scan übersprungen werden und die Installation manuell gestartet werden.
## 🚀 Entwicklungsumgebung

### Voraussetzungen
Stellen Sie sicher, dass folgende Tools auf Ihrem System installiert sind:
* Flutter SDK
* Dart SDK
* Android Studio oder IntelliJ IDEA
* Xcode (für iOS-Entwicklung)

### Projekt starten
1. **Abhängigkeiten installieren:**
   ```bash
   flutter pub get
   ```
2. **Anwendung starten:**
   ```bash
   flutter run
   ```

---

## 📚 Frameworks und Bibliotheken

* **Flutter:** Bildet die Grundlage der mobilen Anwendung und ermöglicht die Entwicklung einer gemeinsamen Codebasis für Android und iOS. Durch das Widget-Konzept lassen sich Benutzeroberflächen modular aufbauen und wiederverwenden.
* **Riverpod:** Wird als State-Management-Lösung eingesetzt. Es verwaltet den zentralen Anwendungszustand und sorgt dafür, dass Änderungen an den Wetterdaten automatisch an alle relevanten Benutzeroberflächen weitergegeben werden.
* **HTTP:** Dient der Kommunikation mit dem FogCast-Backend über REST-Schnittstellen. Die API-Klassen übernehmen dabei den Abruf aktueller Wetterdaten, Wettervorhersagen und historischer Messwerte.
* **SharedPreferences:** Dient zur lokalen Speicherung benutzerspezifischer Einstellungen (z. B. ausgewählte Diagramme im Expertenmodus oder weitere Konfigurationen), die nach einem Neustart der Anwendung automatisch wiederhergestellt werden.
* **FL Chart:** Wird für die Darstellung interaktiver Diagramme verwendet. Sie bildet unter anderem Temperaturverläufe, historische Wasserstände sowie weitere meteorologische Parameter grafisch ab und unterstützt Funktionen wie Scrollen und Tooltips.

---

## 🏗️ Architektur

Die Anwendung basiert auf einer mehrschichtigen Softwarearchitektur:

```text
Benutzeroberfläche
        │
Riverpod State Management
        │
Repositories
        │
API Layer
        │
FogCast Backend
```

Durch diese klare Trennung bleiben Benutzeroberfläche, Datenverwaltung und Datenzugriff voneinander unabhängig. Dies verbessert die Wartbarkeit und erleichtert zukünftige Erweiterungen.

---

## 📄 Dokumentation

Zusätzlich zum Quellcode enthält dieses Repository:
* Projektdokumentation
* Technische Dokumentation
* Implementierungsbeschreibung der mobilen Anwendung

Diese Dokumente beschreiben sowohl den Entwicklungsprozess als auch den technischen Aufbau der App.

---

## 🔮 Ausblick

Die Architektur der FogCast-App ermöglicht eine einfache Erweiterung um zusätzliche Funktionen. Mögliche Weiterentwicklungen umfassen:
* Integration weiterer Wetterparameter (z. B. Wassertemperatur)
* Unterstützung mehrerer Wetterstationen
* Push-Benachrichtigungen bei kritischen Wetterereignissen
* Offline-Verfügbarkeit ausgewählter Wetterdaten
* Erweiterte Analyse- und Visualisierungsfunktionen im Expertenmodus
* Optimierung der Benutzeroberfläche und weiterer Diagrammtypen