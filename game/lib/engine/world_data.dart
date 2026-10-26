/// Starter country data for the prototype. Full country rules come later
/// (Module 10); for now each country has cities and name pools.
class CountryData {
  const CountryData({
    required this.name,
    required this.cities,
    required this.male,
    required this.female,
    required this.surnames,
    required this.currency,
  });

  final String name;
  final List<String> cities;
  final List<String> male;
  final List<String> female;
  final List<String> surnames;
  final String currency;
}

const countries = <CountryData>[
  CountryData(
    name: 'Portugal',
    cities: ['Lisbon', 'Porto', 'Coimbra', 'Faro'],
    male: ['João', 'Rui', 'Tiago', 'Miguel', 'André', 'Pedro', 'Leo'],
    female: ['Maria', 'Inês', 'Beatriz', 'Ana', 'Sofia', 'Marta', 'Leonor'],
    surnames: ['Silva', 'Santos', 'Ferreira', 'Matos', 'Costa', 'Rocha'],
    currency: '€',
  ),
  CountryData(
    name: 'Nigeria',
    cities: ['Lagos', 'Abuja', 'Ibadan', 'Enugu'],
    male: ['Chidi', 'Tunde', 'Emeka', 'Femi', 'Ifeanyi', 'Leo', 'Obi'],
    female: ['Amara', 'Ngozi', 'Maya', 'Funmi', 'Chioma', 'Ada', 'Zainab'],
    surnames: ['Okafor', 'Adeyemi', 'Okonkwo', 'Bello', 'Eze', 'Balogun'],
    currency: '₦',
  ),
  CountryData(
    name: 'United States',
    cities: ['Chicago', 'Austin', 'Seattle', 'Atlanta'],
    male: ['Jordan', 'Mason', 'Ethan', 'Marcus', 'Diego', 'Leo', 'Caleb'],
    female: ['Ava', 'Maya', 'Harper', 'Jasmine', 'Riley', 'Elena', 'Grace'],
    surnames: ['Johnson', 'Rivera', 'Carter', 'Nguyen', 'Brooks', 'Hayes'],
    currency: '\$',
  ),
  CountryData(
    name: 'Philippines',
    cities: ['Manila', 'Cebu', 'Davao', 'Iloilo'],
    male: ['Paolo', 'Miguel', 'Joshua', 'Carlo', 'Rafael', 'Leo', 'Marco'],
    female: ['Andrea', 'Bea', 'Isabel', 'Camille', 'Joy', 'Maya', 'Trisha'],
    surnames: ['Santos', 'Reyes', 'Cruz', 'Bautista', 'Garcia', 'Mendoza'],
    currency: '₱',
  ),
  CountryData(
    name: 'Ireland',
    cities: ['Dublin', 'Cork', 'Galway', 'Limerick'],
    male: ['Cian', 'Oisín', 'Conor', 'Darragh', 'Seán', 'Leo', 'Rory'],
    female: ['Aoife', 'Saoirse', 'Niamh', 'Ciara', 'Róisín', 'Maeve', 'Orla'],
    surnames: ['Murphy', 'Kelly', 'Byrne', 'Walsh', 'Ryan', "O'Brien"],
    currency: '€',
  ),
  CountryData(
    name: 'Netherlands',
    cities: ['Amsterdam', 'Utrecht', 'Rotterdam', 'Groningen'],
    male: ['Daan', 'Sem', 'Lucas', 'Milan', 'Bram', 'Leo', 'Thijs'],
    female: ['Emma', 'Julia', 'Sanne', 'Fenna', 'Lotte', 'Noor', 'Mila'],
    surnames: ['de Jong', 'Jansen', 'Bakker', 'Visser', 'Smit', 'Mulder'],
    currency: '€',
  ),
];

CountryData countryNamed(String name) =>
    countries.firstWhere((c) => c.name == name, orElse: () => countries.first);
