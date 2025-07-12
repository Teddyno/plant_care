/*
 * THEMES - SISTEMA DI DESIGN DELL'APPLICAZIONE
 * 
 * Questo file contiene la configurazione del tema principale dell'app.
 * Definisce l'aspetto visivo globale dell'applicazione con una palette di colori
 * verde floreale ispirata alla natura e alle piante.
 * 
 */

import 'package:flutter/material.dart';

// Tema principale dell'applicazione PlantCare.
final ThemeData appTheme = ThemeData(

  // Font principale dell'applicazione
  fontFamily: 'Roboto',
  
  // Schema colori basato su verde floreale
  // ColorScheme.fromSeed genera automaticamente una palette
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
  scaffoldBackgroundColor: const Color(0xFFF1F8E9),
  
  // Stile della barra superiore (AppBar)
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF43A047), // Verde principale
    foregroundColor: Colors.white,      // Testo bianco
    elevation: 0,                       // Nessuna ombra
    centerTitle: true,                  // Titolo centrato
  ),
  
  // Stile del pulsante flottante
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Color(0xFF43A047), // Verde principale
    foregroundColor: Colors.white,      // Icona bianca
  ),
  
  // Stile dei pulsanti elevati
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
  // (piante, attività, statistiche)
  cardTheme: CardThemeData(
    color: const Color(0xFFE8F5E9),           // Verde chiaro
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12), // Bordi arrotondati
    ),
    elevation: 2,                             // Ombra leggera
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
  
  // Abilita Material 3 
  useMaterial3: true,
);
