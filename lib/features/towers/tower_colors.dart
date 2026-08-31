import 'package:flutter/material.dart';

/// Barvy stavu rozhledny. Používá je značka na mapě, detail i seznam, takže
/// patří na jedno místo — natvrdo zapsaný odstín se jinak při každé úpravě
/// změní jen na některých obrazovkách a stav pak vypadá pokaždé jinak.
///
/// Zeleň je jasnější než primární barva aplikace schválně: turistický podklad
/// je sám zelený a tmavší odstín se v lesnatých oblastech ztrácel.
const visitedColor = Color(0xFF16A34A);
const unvisitedColor = Color(0xFF757575);
