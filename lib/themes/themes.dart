/*
 * THEMES - SISTEMA DI DESIGN DELL'APPLICAZIONE
 * 
 * Questo file contiene la configurazione del tema principale dell'app FloraManager.
 * Definisce l'aspetto visivo globale dell'applicazione con una palette di colori
 * verde floreale ispirata alla natura e alle piante.
 * 
 * Il tema è applicato globalmente tramite la proprietà 'theme' in MaterialApp (vedi main.dart)
 */

import 'package:flutter/material.dart';

/// Tema principale dell'applicazione FloraManager.
/// 
/// Questo tema definisce l'aspetto visivo globale dell'app con:
/// - Palette di colori verde floreale ispirata alla natura
/// - Material 3 design system per un look moderno
/// - Font Roboto per ottima leggibilità
/// - Stili coerenti per tutti i componenti
/// - Bordi arrotondati e ombre sottili
final ThemeData appTheme = ThemeData(
  // Font principale dell'applicazione
  // Roboto è il font standard di Material Design
  // Offre ottima leggibilità su tutti i dispositivi
  fontFamily: 'Roboto',
  
  // Schema colori basato su verde floreale
  // ColorScheme.fromSeed genera automaticamente una palette
  // coerente partendo dal colore seme (seedColor)
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF43A047), // Verde floreale principale
    primary: const Color(0xFF43A047),   // Verde brillante per elementi primari
    secondary: const Color(0xFFB2FF59), // Verde chiaro per elementi secondari
    background: const Color(0xFFF1F8E9), // Verde molto chiaro per lo sfondo
    surface: const Color(0xFFE8F5E9),    // Verde chiaro per le superfici
    onPrimary: Colors.white,             // Testo su elementi primari
    onSecondary: Colors.black,           // Testo su elementi secondari
    onBackground: Colors.black,          // Testo sullo sfondo
    onSurface: Colors.black,             // Testo sulle superfici
    brightness: Brightness.light,        // Tema chiaro
  ),
  
  // Colore di sfondo dello scaffold
  // Scaffold è il widget base per le schermate
  // Questo colore viene usato come sfondo principale
  scaffoldBackgroundColor: const Color(0xFFF1F8E9),
  
  // Stile della barra superiore (AppBar)
  // Definisce l'aspetto delle barre di navigazione
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF43A047), // Verde principale
    foregroundColor: Colors.white,      // Testo bianco
    elevation: 0,                       // Nessuna ombra (design flat)
    centerTitle: true,                  // Titolo centrato
  ),
  
  // Stile del pulsante flottante
  // FloatingActionButton è usato per aggiungere nuove piante
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF43A047), // Verde principale
    foregroundColor: Colors.white,      // Icona bianca
  ),
  
  // Stile dei pulsanti elevati
  // ElevatedButton è usato per azioni principali
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF43A047), // Verde principale
      foregroundColor: Colors.white,            // Testo bianco
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Bordi arrotondati moderni
      ),
    ),
  ),
  
  // Stile delle card
  // Card sono usate per contenere informazioni
  // (piante, attività, statistiche)
  cardTheme: CardThemeData(
    color: const Color(0xFFE8F5E9),           // Verde chiaro
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordi arrotondati
    ),
    elevation: 2,                             // Ombra leggera per profondità
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
  ),
  
  // Stile dei campi di input
  // InputDecorationTheme si applica a TextFormField
  // e altri widget di input
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), // Bordi arrotondati
    ),
    filled: true,                             // Sfondo riempito
    fillColor: const Color(0xFFE8F5E9),       // Verde chiaro
  ),
  
  // Abilita Material 3 per design moderno
  // Material 3 è la versione più recente del design system
  // Offre componenti più moderni e accessibili
  useMaterial3: true,
);
