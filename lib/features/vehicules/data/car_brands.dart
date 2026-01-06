import 'package:diacritic/diacritic.dart';

/// Liste brute des marques (NE PAS trier ici)
const List<String> _rawCarBrands = [
  'Audi',
  'BMW',
  'Mercedes-Benz',
  'Volkswagen',
  'Porsche',
  'Opel',
  'Ford',
  'Renault',
  'Peugeot',
  'Citroën',
  'Dacia',
  'Fiat',
  'Alfa Romeo',
  'Lancia',
  'Skoda',
  'Seat',
  'Cupra',
  'Volvo',
  'Mini',
  'Land Rover',
  'Jaguar',
  'Toyota',
  'Lexus',
  'Nissan',
  'Honda',
  'Mazda',
  'Mitsubishi',
  'Suzuki',
  'Subaru',
  'Isuzu',
  'Hyundai',
  'Kia',
  'Genesis',
  'SsangYong',
  'Chevrolet',
  'GMC',
  'Jeep',
  'Dodge',
  'Chrysler',
  'Cadillac',
  'Tesla',
  'BYD',
  'Chery',
  'Geely',
  'Great Wall',
  'Haval',
  'Dongfeng',
  'BAIC',
  'Tata',
  'Mahindra',
  'Iran Khodro',
  'Saipa',
  'Lada',
  'IVECO',
  'MAN',
  'Scania',
  'DAF',
  'Autre',
];

/// Renvoie la liste finale :
/// - tri alphabétique (sans accents)
/// - "Autre" toujours à la fin
List<String> getCarBrands() {
  final brands = List<String>.from(_rawCarBrands);

  // Retirer "Autre"
  brands.removeWhere(
        (e) => e.toLowerCase() == 'autre',
  );

  // Tri alphabétique robuste (accents ignorés)
  brands.sort(
        (a, b) => removeDiacritics(a).compareTo(
      removeDiacritics(b),
    ),
  );

  // Ajouter "Autre" à la fin
  brands.add('Autre');

  return brands;
}
