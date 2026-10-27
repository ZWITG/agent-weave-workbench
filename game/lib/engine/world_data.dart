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
  CountryData(
    name: 'United Kingdom',
    cities: ['London', 'Manchester', 'Glasgow', 'Bristol'],
    male: ['Oliver', 'Harry', 'George', 'Jack', 'Noah', 'Leo', 'Arthur'],
    female: ['Olivia', 'Amelia', 'Isla', 'Ava', 'Freya', 'Lily', 'Grace'],
    surnames: ['Smith', 'Jones', 'Taylor', 'Brown', 'Evans', 'Wilson'],
    currency: '£',
  ),
  CountryData(
    name: 'Canada',
    cities: ['Toronto', 'Vancouver', 'Montreal', 'Calgary'],
    male: ['Liam', 'Noah', 'William', 'Lucas', 'Benjamin', 'Leo', 'Ethan'],
    female: ['Olivia', 'Charlotte', 'Emma', 'Amelia', 'Chloé', 'Ava', 'Maya'],
    surnames: ['Tremblay', 'Roy', 'Martin', 'Gagnon', 'Wilson', 'Lee'],
    currency: '\$',
  ),
  CountryData(
    name: 'India',
    cities: ['Mumbai', 'Delhi', 'Bengaluru', 'Chennai'],
    male: ['Aarav', 'Vihaan', 'Arjun', 'Rohan', 'Kabir', 'Ishaan', 'Aditya'],
    female: ['Ananya', 'Diya', 'Priya', 'Saanvi', 'Meera', 'Kavya', 'Maya'],
    surnames: ['Sharma', 'Patel', 'Singh', 'Iyer', 'Reddy', 'Nair'],
    currency: '₹',
  ),
  CountryData(
    name: 'Japan',
    cities: ['Tokyo', 'Osaka', 'Kyoto', 'Sapporo'],
    male: ['Haruto', 'Ren', 'Sota', 'Yuto', 'Hinata', 'Kaito', 'Riku'],
    female: ['Himari', 'Yui', 'Aoi', 'Sakura', 'Mei', 'Hana', 'Rin'],
    surnames: ['Sato', 'Suzuki', 'Takahashi', 'Tanaka', 'Watanabe', 'Ito'],
    currency: '¥',
  ),
  CountryData(
    name: 'Brazil',
    cities: ['São Paulo', 'Rio de Janeiro', 'Salvador', 'Belo Horizonte'],
    male: ['Miguel', 'Arthur', 'Gael', 'Heitor', 'Davi', 'Gabriel', 'Pedro'],
    female: [
      'Helena',
      'Alice',
      'Laura',
      'Valentina',
      'Sophia',
      'Júlia',
      'Maya',
    ],
    surnames: ['Silva', 'Oliveira', 'Souza', 'Lima', 'Pereira', 'Costa'],
    currency: 'R\$',
  ),
  CountryData(
    name: 'Germany',
    cities: ['Berlin', 'Hamburg', 'Munich', 'Cologne'],
    male: ['Noah', 'Leon', 'Paul', 'Finn', 'Elias', 'Felix', 'Jonas'],
    female: ['Emilia', 'Mia', 'Hannah', 'Emma', 'Lea', 'Clara', 'Lina'],
    surnames: ['Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Wagner'],
    currency: '€',
  ),
  CountryData(
    name: 'Australia',
    cities: ['Sydney', 'Melbourne', 'Brisbane', 'Perth'],
    male: ['Oliver', 'Noah', 'Jack', 'William', 'Leo', 'Henry', 'Thomas'],
    female: ['Charlotte', 'Olivia', 'Amelia', 'Isla', 'Mia', 'Ava', 'Matilda'],
    surnames: ['Smith', 'Jones', 'Williams', 'Brown', 'Nguyen', 'Taylor'],
    currency: '\$',
  ),
  CountryData(
    name: 'Mexico',
    cities: ['Mexico City', 'Guadalajara', 'Monterrey', 'Puebla'],
    male: ['Santiago', 'Mateo', 'Sebastián', 'Leonardo', 'Diego', 'Emiliano'],
    female: ['Sofía', 'Valentina', 'Regina', 'Camila', 'Ximena', 'Renata'],
    surnames: ['Hernández', 'García', 'Martínez', 'López', 'González', 'Pérez'],
    currency: '\$',
  ),
];

CountryData countryNamed(String name) =>
    countries.firstWhere((c) => c.name == name, orElse: () => countries.first);

/// Country profile (plan Module 10, starter data): the facts that change
/// how a life plays out there. Shown on the Me tab and when emigrating.
class CountryProfile {
  const CountryProfile({
    required this.lifeExpectancy,
    required this.healthcare,
    required this.drivingAge,
    required this.drinkingAge,
    required this.gamblingAge,
    required this.marriageEquality,
    required this.deathPenalty,
    required this.climate,
    required this.languages,
    required this.blurb,
  });

  final int lifeExpectancy;

  /// universal, insurance or out of pocket.
  final String healthcare;
  final int drivingAge;
  final int drinkingAge;
  final int gamblingAge;
  final bool marriageEquality;
  final bool deathPenalty;

  /// supportive, mixed or hostile (legal and social climate for LGBTQ+
  /// people, used gently in coming-out reactions and travel warnings).
  final String climate;
  final List<String> languages;
  final String blurb;
}

const _profiles = <String, CountryProfile>{
  'Portugal': CountryProfile(
    lifeExpectancy: 81,
    healthcare: 'universal',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['Portuguese'],
    blurb: 'Sunny coasts, custard tarts and a slow, warm pace of life.',
  ),
  'Nigeria': CountryProfile(
    lifeExpectancy: 54,
    healthcare: 'out of pocket',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: false,
    deathPenalty: true,
    climate: 'hostile',
    languages: ['English'],
    blurb: 'Africa\'s most populous country: huge energy, music and hustle.',
  ),
  'United States': CountryProfile(
    lifeExpectancy: 77,
    healthcare: 'insurance',
    drivingAge: 16,
    drinkingAge: 21,
    gamblingAge: 21,
    marriageEquality: true,
    deathPenalty: true,
    climate: 'mixed',
    languages: ['English'],
    blurb: 'Big cities, big dreams and health insurance worth thinking about.',
  ),
  'Philippines': CountryProfile(
    lifeExpectancy: 70,
    healthcare: 'out of pocket',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 21,
    marriageEquality: false,
    deathPenalty: false,
    climate: 'mixed',
    languages: ['Filipino', 'English'],
    blurb: 'Seven thousand islands and family at the centre of everything.',
  ),
  'Ireland': CountryProfile(
    lifeExpectancy: 82,
    healthcare: 'universal',
    drivingAge: 17,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['English', 'Irish'],
    blurb: 'Green hills, good talk and rain that never quite stops.',
  ),
  'Netherlands': CountryProfile(
    lifeExpectancy: 82,
    healthcare: 'universal',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['Dutch'],
    blurb: 'Bicycles, canals and very direct opinions.',
  ),
  'United Kingdom': CountryProfile(
    lifeExpectancy: 81,
    healthcare: 'universal',
    drivingAge: 17,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['English'],
    blurb: 'Queues, tea, history on every corner and opinions about weather.',
  ),
  'Canada': CountryProfile(
    lifeExpectancy: 82,
    healthcare: 'universal',
    drivingAge: 16,
    drinkingAge: 19,
    gamblingAge: 19,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['English', 'French'],
    blurb: 'Huge, cold, kind and very good at apologising.',
  ),
  'India': CountryProfile(
    lifeExpectancy: 70,
    healthcare: 'out of pocket',
    drivingAge: 18,
    drinkingAge: 21,
    gamblingAge: 21,
    marriageEquality: false,
    deathPenalty: true,
    climate: 'mixed',
    languages: ['Hindi', 'English'],
    blurb: 'A billion stories, a hundred languages and the best street food.',
  ),
  'Japan': CountryProfile(
    lifeExpectancy: 84,
    healthcare: 'universal',
    drivingAge: 18,
    drinkingAge: 20,
    gamblingAge: 20,
    marriageEquality: false,
    deathPenalty: true,
    climate: 'mixed',
    languages: ['Japanese'],
    blurb: 'Trains on time to the second, quiet temples and neon nights.',
  ),
  'Brazil': CountryProfile(
    lifeExpectancy: 76,
    healthcare: 'universal',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'mixed',
    languages: ['Portuguese'],
    blurb: 'Football, beaches, carnival and family lunches that last all day.',
  ),
  'Germany': CountryProfile(
    lifeExpectancy: 81,
    healthcare: 'universal',
    drivingAge: 17,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['German'],
    blurb: 'Efficient, green and serious about bread.',
  ),
  'Australia': CountryProfile(
    lifeExpectancy: 83,
    healthcare: 'universal',
    drivingAge: 17,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'supportive',
    languages: ['English'],
    blurb: 'Beaches, barbecues and wildlife with opinions.',
  ),
  'Mexico': CountryProfile(
    lifeExpectancy: 75,
    healthcare: 'out of pocket',
    drivingAge: 18,
    drinkingAge: 18,
    gamblingAge: 18,
    marriageEquality: true,
    deathPenalty: false,
    climate: 'mixed',
    languages: ['Spanish'],
    blurb: 'Colour, history, family and food that ruins every other cuisine.',
  ),
};

CountryProfile countryProfile(String name) =>
    _profiles[name] ?? _profiles['Portugal']!;
