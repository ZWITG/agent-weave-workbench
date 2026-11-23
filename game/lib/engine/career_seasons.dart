part of 'career_hub.dart';

// The season tabs on every Career Hub. Each career's four tabs open a
// choice of their own (a posting, a studio, a corner, a script...) and each
// career has a signature mechanic that runs through all four:
//
//   Armed forces  Fatigue (boot prints, 0–5)      Athlete    Fatigue vs Form
//   Musician      Setlist (songs, rated 1–5)      Actor      Typecast
//   Politician    Whip vs Conscience              Police     Clean or dirty file
//   Model         Image (wholesome ↔ edgy)        Doctor     Burnout
//   Lawyer        Win record and Ethics           Vet        Farm trust
//   Pilot         Logbook stamps                  Hustler    The pitch map
//   Astronaut     Mission countdown               Fighter    Damage
//
// Once a year you pick one tab and one of its options. The highlighted tab
// (the season now) counts for more. State lives in Life.hub.

enum SeasonKind { prep, push, big, rest }

/// One choice inside a season tab.
class SeasonOpt {
  const SeasonOpt(
    this.id,
    this.label,
    this.kind, {
    this.blurb = '',
    this.meter = 0,
    this.fail,
    this.odds,
    this.stats = const {},
    this.pay = 0,
    this.sig = 0,
    this.count,
    this.hurt = 0,
    this.win = '',
    this.lose = '',
    this.miniGame,
    this.tag,
    this.icon = 'dot',
  });

  final String id, label, blurb, win, lose, icon;
  final SeasonKind kind;

  /// Meter on a good result, and on a bad one (null: a default by kind).
  final int meter;
  final int? fail;

  /// Base odds of a good result (null: a default by kind).
  final int? odds;
  final Map<String, int> stats;

  /// Money on a good result (negative: what it costs).
  final int pay;

  /// How the career's signature mechanic moves.
  final int sig;

  /// A Hub counter a good result adds to (medals, titles...).
  final String? count;

  /// Health lost on a bad result.
  final int hurt;
  final String? miniGame;

  /// Extra data the career reads (a genre, a corner, a route...).
  final String? tag;
}

/// One season tab: what it asks and its options.
class SeasonTab {
  const SeasonTab(this.prompt, this.opts, {this.art});
  final String prompt;
  final List<SeasonOpt> opts;

  /// A drawing for the top of the tab's sheet (career_signature.dart).
  final String? art;
}

const _prep = SeasonKind.prep,
    _push = SeasonKind.push,
    _big = SeasonKind.big,
    _rest = SeasonKind.rest;

// ---------------- Every career's tabs ----------------

const _seasonTabs = <String, List<SeasonTab>>{
  'military': [
    SeasonTab('Pick a course.', [
      SeasonOpt(
        'assault',
        'Assault course',
        _push,
        blurb: 'Wall, net, rope, ditch. Reps mini-game.',
        meter: 7,
        odds: 70,
        sig: 1,
        miniGame: 'reps',
        icon: 'fitness',
        stats: {'athleticism': 2},
        win: 'You went over the wall like it wasn\'t there and beat the platoon record.',
        lose: 'The rope won. The sergeant had a lot to say about it.',
      ),
      SeasonOpt(
        'marks',
        'Marksmanship',
        _push,
        blurb: 'Steady breath, squeeze. Timing mini-game.',
        meter: 6,
        odds: 65,
        sig: 1,
        miniGame: 'timing',
        count: 'badges',
        icon: 'target',
        win: 'Tight groups at 300 metres. You earned the Marksman badge.',
        lose: 'Your shots wandered all over the target.',
      ),
      SeasonOpt(
        'officer',
        'Officer school',
        _push,
        blurb: 'Tactics and leadership. Needed for Lieutenant. Quiz mini-game.',
        meter: 6,
        odds: 50,
        sig: 1,
        miniGame: 'quiz',
        icon: 'school',
        stats: {'smarts': 2},
        win: 'Twelve weeks of tactics and leadership. You passed the officer course.',
        lose: 'The board said "not yet". You can try again next year.',
      ),
    ]),
    SeasonTab('Choose your section\'s route across the moor.', [
      SeasonOpt(
        'road',
        'The road',
        _push,
        blurb: 'Safe and slow.',
        meter: 4,
        odds: 88,
        sig: 1,
        icon: 'road',
        win: 'Long and dull, but your section arrived together and on time.',
        lose: 'The road was longer than the map said. You came in last.',
      ),
      SeasonOpt(
        'ridge',
        'The ridge',
        _push,
        blurb: 'Exposed, but quick.',
        meter: 7,
        odds: 60,
        sig: 1,
        icon: 'terrain',
        win: 'You held the high ground and took the objective by surprise.',
        lose: 'The enemy saw you coming along the skyline.',
      ),
      SeasonOpt(
        'bog',
        'The bog',
        _big,
        blurb: 'The short cut the map says to avoid.',
        meter: 10,
        fail: -4,
        odds: 45,
        sig: 1,
        hurt: 3,
        count: 'commendations',
        icon: 'water',
        win: 'Wet to the waist and first to the checkpoint. A Commendation for your record.',
        lose: 'The bog took a boot and most of your pride.',
      ),
    ], art: 'moor'),
    SeasonTab('Choose your posting.', [
      SeasonOpt(
        'peace',
        'Peacekeeping',
        _push,
        blurb: 'Safe. Good for the soul.',
        meter: 6,
        odds: 85,
        sig: 1,
        pay: 2000,
        stats: {'karma': 3},
        icon: 'shield',
        win: 'Six months keeping two sides apart. Nobody fired a shot.',
        lose: 'A tense tour. You kept the peace, just.',
      ),
      SeasonOpt(
        'front',
        'Frontline',
        _big,
        blurb: 'The best chance of a medal, and the worst injury risk.',
        meter: 14,
        fail: -6,
        sig: 2,
        pay: 5000,
        count: 'medals',
        hurt: 6,
        icon: 'target',
        win: 'A hard tour on the front line. You came home with a medal.',
        lose: 'Shrapnel in the leg and a long flight home.',
      ),
      SeasonOpt(
        'rescue',
        'Rescue mission',
        _big,
        blurb: 'Get civilians out. The papers may hear about it.',
        meter: 10,
        fail: -4,
        odds: 50,
        sig: 2,
        pay: 3000,
        count: 'rescues',
        hurt: 3,
        tag: 'fame',
        icon: 'helicopter',
        win: 'You got forty civilians out before the bridge went. The news ran your photo.',
        lose: 'The road was blocked. You got some of them out.',
      ),
    ]),
    SeasonTab('Where do you spend it?', [
      SeasonOpt(
        'home',
        'Home',
        _rest,
        blurb: 'Family time. Clears Fatigue.',
        meter: -3,
        sig: -5,
        tag: 'family',
        stats: {'happiness': 5, 'health': 3},
        icon: 'home',
        win: 'Your own bed, real food and the family round the table.',
      ),
      SeasonOpt(
        'abroad',
        'Travel abroad',
        _rest,
        blurb: 'Clears Fatigue.',
        meter: -3,
        sig: -5,
        pay: -1500,
        stats: {'happiness': 8, 'health': 2},
        icon: 'flight',
        win: 'Two weeks somewhere warm where nobody shouted at dawn.',
      ),
      SeasonOpt(
        'wild',
        'A wild week',
        _push,
        blurb: 'The best week of your life, if you are back on time.',
        meter: -2,
        fail: -8,
        odds: 70,
        sig: -5,
        stats: {'happiness': 10},
        icon: 'party',
        win: 'A legendary week. You made it back with an hour to spare.',
        lose: 'You came back two days late. Absent without leave.',
      ),
    ]),
  ],
  'athlete': [
    SeasonTab('Choose the training block.', [
      SeasonOpt(
        'light',
        'Light',
        _prep,
        blurb: 'Fresh legs.',
        meter: 3,
        sig: 5,
        icon: 'walk',
        win: 'An easy pre-season. You feel fresh.',
      ),
      SeasonOpt(
        'hard',
        'Hard',
        _prep,
        blurb: 'Real gains.',
        meter: 6,
        sig: 20,
        stats: {'athleticism': 2},
        icon: 'run',
        win: 'Hill sprints and the weights room. Your Form is building.',
      ),
      SeasonOpt(
        'brutal',
        'Brutal',
        _prep,
        blurb: 'The biggest gains and the biggest injury risk.',
        meter: 10,
        sig: 40,
        stats: {'athleticism': 3},
        icon: 'fire',
        win: 'Double sessions every day. You have never been this sharp, or this tired.',
      ),
    ]),
    SeasonTab('Three match days.', [
      SeasonOpt(
        'play',
        'Play every minute',
        _push,
        blurb: 'Reaction mini-game.',
        meter: 7,
        odds: 55,
        sig: 15,
        miniGame: 'reaction',
        icon: 'ball',
        win: 'Match-winning performances. The coach stopped rotating you.',
        lose: 'A patchy run. You kept the shirt, just.',
      ),
      SeasonOpt(
        'rotate',
        'Rotate and rest',
        _rest,
        blurb: 'Fewer minutes, fresher legs.',
        meter: 1,
        sig: -25,
        icon: 'bench',
        win: 'You came off the bench and kept your legs fresh.',
      ),
    ]),
    SeasonTab('The final moment.', [
      SeasonOpt(
        'shot',
        'Take the decisive shot',
        _big,
        blurb: 'Timing mini-game. Win it and it goes in the trophy cabinet.',
        meter: 12,
        fail: -5,
        sig: 10,
        pay: 5000,
        count: 'titles',
        miniGame: 'timing',
        icon: 'trophy',
        win: 'You put it in the top corner. Champions.',
        lose: 'The keeper guessed right. You will see it in your sleep.',
      ),
      SeasonOpt(
        'team',
        'Play for the team',
        _push,
        blurb: 'Set up a teammate.',
        meter: 5,
        odds: 65,
        sig: 8,
        stats: {'karma': 2},
        icon: 'group',
        win: 'Your assist won it. The dressing room knows who made it.',
        lose: 'The pass went astray. Out in the play-offs.',
      ),
    ], art: 'goal'),
    SeasonTab('The contract table.', [
      SeasonOpt(
        'loyal',
        'Stay loyal',
        _rest,
        blurb: 'The fans love you for it.',
        meter: 2,
        sig: -30,
        stats: {'happiness': 4, 'karma': 2},
        icon: 'heart',
        win: 'You signed again. The fans sang your name.',
      ),
      SeasonOpt(
        'transfer',
        'Push for a transfer',
        _push,
        blurb: 'A bigger club and a raise, if your agent pulls it off.',
        meter: 4,
        fail: -2,
        odds: 50,
        sig: -30,
        tag: 'raise',
        icon: 'swap',
        win: 'A bigger club came in for you, with a 20% raise.',
        lose: 'The deal collapsed and the fans heard about it.',
      ),
      SeasonOpt(
        'sponsor',
        'Sign a sponsor',
        _rest,
        blurb: 'Boots, drinks, a watch.',
        meter: 1,
        sig: -30,
        pay: 6000,
        icon: 'money',
        win: 'Your face is on a sports drink now.',
      ),
    ]),
  ],
  'musician': [
    SeasonTab('Pick a mood for a new song.', [
      SeasonOpt(
        'love',
        'Love song',
        _prep,
        blurb: 'Memory mini-game sets how good it is.',
        meter: 3,
        miniGame: 'memory',
        tag: 'love',
        icon: 'heart',
        stats: {'creativity': 2},
        win: 'A love song came out in one sitting.',
      ),
      SeasonOpt(
        'anthem',
        'Anthem',
        _prep,
        blurb: 'Memory mini-game.',
        meter: 3,
        miniGame: 'memory',
        tag: 'anthem',
        icon: 'flag',
        stats: {'creativity': 2},
        win: 'A big chorus for a big room.',
      ),
      SeasonOpt(
        'protest',
        'Protest song',
        _prep,
        blurb: 'Memory mini-game.',
        meter: 3,
        miniGame: 'memory',
        tag: 'protest',
        icon: 'megaphone',
        stats: {'creativity': 2, 'karma': 1},
        win: 'Three chords and the truth.',
      ),
      SeasonOpt(
        'heartbreak',
        'Heartbreak',
        _prep,
        blurb: 'Memory mini-game.',
        meter: 3,
        miniGame: 'memory',
        tag: 'heartbreak',
        icon: 'broken',
        stats: {'creativity': 2},
        win: 'You wrote it at 3 a.m. and cried a bit.',
      ),
    ]),
    SeasonTab('Pick a studio for your newest song.', [
      SeasonOpt(
        'bedroom',
        'Bedroom',
        _prep,
        blurb: 'Free and rough.',
        meter: 3,
        tag: '0',
        icon: 'bed',
        win: 'Recorded under a duvet. It has charm.',
      ),
      SeasonOpt(
        'indie',
        'Indie studio',
        _prep,
        blurb: 'Song quality +1.',
        meter: 5,
        pay: -2000,
        tag: '1',
        icon: 'mic',
        win: 'A proper desk and an engineer who cared.',
      ),
      SeasonOpt(
        'major',
        'Major-label studio',
        _prep,
        blurb: 'Song quality +2.',
        meter: 7,
        pay: -8000,
        tag: '2',
        icon: 'star',
        win: 'Strings, a producer with Grammys and a very polished song.',
      ),
    ]),
    SeasonTab('How do you drop it?', [
      SeasonOpt(
        'surprise',
        'Surprise drop',
        _big,
        blurb: 'Viral or flop. Your best song decides the odds.',
        meter: 14,
        fail: -3,
        pay: 3000,
        count: 'hits',
        icon: 'bolt',
        win: 'You dropped it at midnight and woke up to a million streams.',
        lose: 'It came and went. The algorithm did not notice.',
      ),
      SeasonOpt(
        'single',
        'Single, then album',
        _push,
        blurb: 'Steady.',
        meter: 8,
        odds: 60,
        pay: 1500,
        icon: 'disc',
        win: 'The single climbed and the album followed it.',
        lose: 'A slow build that never quite built.',
      ),
      SeasonOpt(
        'teaser',
        'Short-video teaser',
        _prep,
        blurb: 'Following goes up even if it flops.',
        meter: 5,
        icon: 'phone',
        win: 'Fifteen seconds of the chorus went round the internet.',
      ),
    ]),
    SeasonTab('Pick a route.', [
      SeasonOpt(
        'home',
        'Home cities',
        _prep,
        blurb: 'Small rooms that know the words.',
        meter: 5,
        pay: 1500,
        stats: {'health': -2},
        icon: 'van',
        win: 'Small rooms, every word sung back.',
      ),
      SeasonOpt(
        'circuit',
        'The big circuit',
        _push,
        blurb: 'Bigger rooms, more merch.',
        meter: 9,
        odds: 60,
        pay: 4000,
        stats: {'health': -4},
        icon: 'map',
        win: 'Sold-out rooms and a merch table that kept emptying.',
        lose: 'Half-empty rooms and a van that broke down twice.',
      ),
      SeasonOpt(
        'europe',
        'Europe',
        _big,
        blurb: 'Glasgow, Leeds, Berlin. The setlist has to be good.',
        meter: 14,
        fail: -3,
        pay: 8000,
        stats: {'health': -5},
        count: 'tours',
        icon: 'globe',
        win: 'Berlin sang your best song back at you. An encore every night.',
        lose: 'Long drives to quiet rooms. Next time.',
      ),
    ], art: 'tour'),
  ],
  'actor': [
    SeasonTab('Scripts on your desk. Pick one to read for.', [
      SeasonOpt(
        'drama',
        'The Long Night',
        _push,
        blurb: 'Drama · lead. Rhythm mini-game.',
        meter: 8,
        fail: 1,
        odds: 50,
        pay: 2000,
        miniGame: 'rhythm',
        tag: 'Drama',
        icon: 'mask',
        win: 'You got the part. Filming starts this year.',
        lose: 'They said "thank you" in the way that means no.',
      ),
      SeasonOpt(
        'comedy',
        'Paper Crowns',
        _push,
        blurb: 'Comedy · support. Rhythm mini-game.',
        meter: 8,
        fail: 1,
        odds: 50,
        pay: 2000,
        miniGame: 'rhythm',
        tag: 'Comedy',
        icon: 'smile',
        win: 'Your timing landed. You got the part.',
        lose: 'The joke didn\'t land in the room.',
      ),
      SeasonOpt(
        'action',
        'Northbound',
        _push,
        blurb: 'Action · villain. Rhythm mini-game.',
        meter: 8,
        fail: 1,
        odds: 50,
        pay: 2000,
        miniGame: 'rhythm',
        tag: 'Action',
        icon: 'bolt',
        win: 'You\'ll be hanging off a train in March. You got it.',
        lose: 'They went with someone with bigger arms.',
      ),
      SeasonOpt(
        'horror',
        'The Cellar',
        _push,
        blurb: 'Horror · lead. Rhythm mini-game.',
        meter: 8,
        fail: 1,
        odds: 50,
        pay: 2000,
        miniGame: 'rhythm',
        tag: 'Horror',
        icon: 'moon',
        win: 'Your scream got the job.',
        lose: 'They wanted a different kind of scream.',
      ),
    ], art: 'scripts'),
    SeasonTab('A crisis on set.', [
      SeasonOpt(
        'improv',
        'Improvise a line',
        _push,
        blurb: 'The director might keep it.',
        meter: 7,
        odds: 55,
        stats: {'creativity': 2},
        icon: 'idea',
        win: 'They kept your line. It\'s in the trailer.',
        lose: 'The director said "let\'s go again, as written".',
      ),
      SeasonOpt(
        'diva',
        'Make a demand',
        _prep,
        blurb: 'Money now, Buzz later.',
        meter: -2,
        pay: 5000,
        icon: 'money',
        win: 'A bigger trailer and a bigger fee. The crew rolled their eyes.',
      ),
      SeasonOpt(
        'costar',
        'Time with your co-star',
        _prep,
        blurb: 'Chemistry, on screen and off.',
        meter: 3,
        stats: {'happiness': 4},
        icon: 'heart',
        win: 'The chemistry was real. People are talking.',
      ),
    ]),
    SeasonTab('Pick your red-carpet look.', [
      SeasonOpt(
        'classic',
        'Classic',
        _push,
        blurb: 'Safe and elegant.',
        meter: 6,
        odds: 65,
        tag: 'stars',
        icon: 'star',
        win: 'Elegant and on every best-dressed list. The reviews were kind.',
        lose: 'Nobody remembered what you wore, or the film.',
      ),
      SeasonOpt(
        'bold',
        'Bold',
        _big,
        blurb: 'Looks decide it. Front page or worst-dressed.',
        meter: 12,
        fail: -4,
        tag: 'stars',
        icon: 'bolt',
        win: 'Every camera turned. Five stars in the morning papers.',
        lose: 'The worst-dressed list, and one star for the film.',
      ),
      SeasonOpt(
        'quiet',
        'Understated',
        _prep,
        blurb: 'Let the film talk.',
        meter: 3,
        icon: 'circle',
        win: 'Quietly lovely. The film did the talking.',
      ),
    ]),
    SeasonTab('Awards season.', [
      SeasonOpt(
        'campaign',
        'Run a campaign',
        _big,
        blurb: 'Screenings and lunches. Costs money.',
        meter: 12,
        fail: -2,
        pay: -5000,
        count: 'awards',
        icon: 'trophy',
        win: 'Nominated, then your name in the envelope. Your speech went viral.',
        lose: 'Nominated, and you clapped politely for someone else.',
      ),
      SeasonOpt(
        'work',
        'Let the work speak',
        _big,
        blurb: 'Free, and a long shot.',
        meter: 10,
        fail: 0,
        odds: 25,
        count: 'awards',
        icon: 'film',
        win: 'No campaign, and they gave it to you anyway.',
        lose: 'No nomination this year.',
      ),
      SeasonOpt(
        'skip',
        'Skip the circuit',
        _rest,
        blurb: 'Stay home.',
        meter: -2,
        stats: {'happiness': 5},
        icon: 'home',
        win: 'You watched it in pyjamas.',
      ),
    ]),
  ],
  'politician': [
    SeasonTab('A bill hits the floor. How do you vote?', [
      SeasonOpt(
        'party',
        'With the party',
        _prep,
        blurb: 'The whip remembers loyalty.',
        meter: 2,
        sig: 12,
        icon: 'group',
        win:
            'You voted with the party. The whip nodded at you in the corridor.',
      ),
      SeasonOpt(
        'conscience',
        'With your conscience',
        _push,
        blurb: 'Voters may love it. The whip won\'t.',
        meter: 8,
        fail: -4,
        odds: 55,
        sig: -12,
        icon: 'heart',
        win: 'Your speech went round the country. Voters loved it.',
        lose: 'You rebelled and the bill passed anyway.',
      ),
      SeasonOpt(
        'abstain',
        'Abstain',
        _prep,
        blurb: 'Keep your head down.',
        meter: -1,
        icon: 'circle',
        win: 'You abstained. Nobody noticed, which was the point.',
      ),
    ]),
    SeasonTab('Where does most of the money go?', [
      SeasonOpt(
        'schools',
        'Schools',
        _push,
        blurb: 'Parents happy.',
        meter: 6,
        odds: 65,
        sig: 2,
        stats: {'karma': 2},
        icon: 'school',
        win: 'New classrooms with your name on the plaque.',
        lose: 'The money got lost on the way to the classrooms.',
      ),
      SeasonOpt(
        'hospitals',
        'Hospitals',
        _push,
        blurb: 'Older voters very happy.',
        meter: 7,
        odds: 65,
        sig: 2,
        icon: 'hospital',
        win: 'Waiting lists fell. Older voters will remember.',
        lose: 'Waiting lists didn\'t move.',
      ),
      SeasonOpt(
        'police',
        'Police',
        _push,
        blurb: 'Safer streets, shopkeepers split.',
        meter: 5,
        odds: 60,
        sig: 4,
        icon: 'shield',
        win: 'More officers on the beat.',
        lose: 'Crime went up anyway.',
      ),
      SeasonOpt(
        'tax',
        'Tax cuts',
        _push,
        blurb: 'Business happy.',
        meter: 6,
        odds: 60,
        sig: 6,
        pay: 1000,
        icon: 'money',
        win: 'Business cheered. So did your accountant.',
        lose: 'The cuts were too small to notice.',
      ),
    ], art: 'budget'),
    SeasonTab('Recess.', [
      SeasonOpt(
        'surgery',
        'Constituency surgeries',
        _push,
        blurb: 'Solve voters\' problems.',
        meter: 6,
        odds: 70,
        stats: {'karma': 2},
        icon: 'chat',
        win: 'You fixed a broken lift, a bus route and a feud.',
        lose: 'Long queues and problems you couldn\'t fix.',
      ),
      SeasonOpt(
        'holiday',
        'A real holiday',
        _rest,
        blurb: 'Nobody rings.',
        meter: -2,
        icon: 'sun',
        win: 'A week where nobody rang you.',
      ),
      SeasonOpt(
        'dinners',
        'Fundraising dinners',
        _prep,
        blurb: 'Money for the campaign.',
        meter: 1,
        pay: 3000,
        stats: {'karma': -1},
        icon: 'money',
        win: 'Rubber chicken and a full war chest.',
      ),
    ]),
    SeasonTab('The campaign.', [
      SeasonOpt(
        'debate',
        'Debate head on',
        _big,
        blurb: 'Win the room, win the town.',
        meter: 12,
        fail: -6,
        icon: 'mic',
        win: 'You won the debate on a single line. The polls jumped.',
        lose: 'You froze on the economy question.',
      ),
      SeasonOpt(
        'doors',
        'Door to door',
        _push,
        blurb: 'Tiring, and it works.',
        meter: 7,
        odds: 65,
        stats: {'health': -1},
        icon: 'walk',
        win: 'Ten thousand doors. People remembered your face.',
        lose: 'Lots of doors, lots of dogs, not many votes.',
      ),
      SeasonOpt(
        'ads',
        'Attack ads',
        _push,
        blurb: 'Effective and grubby.',
        meter: 8,
        odds: 55,
        stats: {'karma': -3},
        icon: 'bolt',
        win: 'The ads worked. You felt a bit grubby.',
        lose: 'The ads backfired on you.',
      ),
    ]),
  ],
  'police': [
    SeasonTab('Three encounters on your patch.', [
      SeasonOpt(
        'book',
        'By the book',
        _prep,
        blurb: 'Arrest, warn, move on.',
        meter: 4,
        icon: 'shield',
        win: 'You learned every shopkeeper\'s name and wrote everything down.',
      ),
      SeasonOpt(
        'blind',
        'Look the other way',
        _prep,
        blurb: 'Take the envelope. Your file won\'t like it.',
        meter: 0,
        sig: 1,
        pay: 1500,
        stats: {'karma': -3},
        icon: 'money',
        win: 'An envelope in your jacket and a dealer back on his corner.',
      ),
      SeasonOpt(
        'dealer',
        'Go after the dealer',
        _big,
        blurb: 'A real case, if you catch him.',
        meter: 12,
        fail: 0,
        hurt: 3,
        icon: 'run',
        win: 'A foot chase, an arrest and a case closed.',
        lose: 'He got over the fence. You didn\'t.',
      ),
    ]),
    SeasonTab('The evidence board.', [
      SeasonOpt(
        'board',
        'Work the board',
        _push,
        blurb: 'Memory mini-game: match the clues.',
        meter: 12,
        fail: 0,
        odds: 50,
        miniGame: 'memory',
        icon: 'search',
        win: 'The red string led to one name. Case closed.',
        lose: 'Every lead went cold.',
      ),
      SeasonOpt(
        'lean',
        'Lean on a suspect',
        _push,
        blurb: 'Quicker. Your file won\'t like it.',
        meter: 12,
        fail: 0,
        odds: 65,
        sig: 1,
        icon: 'fist',
        win: 'He talked. You didn\'t ask how nicely.',
        lose: 'He lawyered up, and complained.',
      ),
    ], art: 'board'),
    SeasonTab('In the witness box.', [
      SeasonOpt(
        'notes',
        'Stick to your notes',
        _push,
        blurb: 'Safe.',
        meter: 12,
        fail: 0,
        odds: 60,
        icon: 'notes',
        win: 'Your evidence stood up. Guilty.',
        lose: 'The defence found a hole in your notes.',
      ),
      SeasonOpt(
        'embellish',
        'Embellish',
        _push,
        blurb: 'A surer conviction and a mark on your file.',
        meter: 12,
        fail: 0,
        odds: 85,
        sig: 1,
        icon: 'pen',
        win: 'A few extra details and a conviction.',
        lose: 'The defence caught it. So did Internal Affairs.',
      ),
    ]),
    SeasonTab('The review board.', [
      SeasonOpt(
        'panel',
        'Sit the promotion panel',
        _push,
        blurb: 'Your file matters.',
        meter: 4,
        odds: 55,
        icon: 'badge',
        win: 'The panel was impressed with your record.',
        lose: 'The panel had questions about your record.',
      ),
      SeasonOpt(
        'leave',
        'Take your leave',
        _rest,
        blurb: 'Sleep and paperwork.',
        meter: 0,
        icon: 'home',
        win: 'Your paperwork, your leave and your sleep caught up.',
      ),
    ]),
  ],
  'model': [
    SeasonTab('Pick an agency board.', [
      SeasonOpt(
        'fashion',
        'High fashion',
        _push,
        blurb: 'Prestige. Pulls your Image edgy.',
        meter: 8,
        odds: 50,
        sig: 8,
        icon: 'star',
        win: 'An editor booked you for a cover test.',
        lose: 'Too commercial, they said.',
      ),
      SeasonOpt(
        'commercial',
        'Commercial',
        _prep,
        blurb: 'Money. Pulls your Image wholesome.',
        meter: 4,
        pay: 3000,
        sig: -8,
        icon: 'money',
        win: 'Catalogues and a toothpaste advert.',
      ),
      SeasonOpt(
        'fitness',
        'Fitness',
        _prep,
        blurb: 'Health and sportswear.',
        meter: 4,
        stats: {'health': 3},
        icon: 'run',
        win: 'Sportswear shoots and a lot of planks.',
      ),
    ]),
    SeasonTab('Fashion week.', [
      SeasonOpt(
        'walk',
        'Walk the shows',
        _big,
        blurb: 'Timing mini-game. Nail the turn.',
        meter: 12,
        fail: -3,
        miniGame: 'timing',
        pay: 5000,
        count: 'shows',
        tag: 'fame',
        icon: 'walk',
        win: 'You opened one show and closed another.',
        lose: 'One small show, and you nearly fell on the turn.',
      ),
      SeasonOpt(
        'party',
        'The parties',
        _prep,
        blurb: 'Pulls your Image edgy.',
        meter: 2,
        sig: 12,
        stats: {'happiness': 5},
        icon: 'party',
        win: 'You were photographed leaving three parties.',
      ),
    ]),
    SeasonTab('Three campaign offers.', [
      SeasonOpt(
        'luxury',
        'Maison (luxury)',
        _push,
        blurb: 'Portfolio. Wants a balanced Image.',
        meter: 10,
        odds: 50,
        icon: 'diamond',
        win: 'A luxury house shot you in Paris.',
        lose: 'They went with a quieter face.',
      ),
      SeasonOpt(
        'fast',
        'Quik (fast fashion)',
        _prep,
        blurb: 'Cash. Wholesome.',
        meter: 2,
        pay: 12000,
        sig: -5,
        icon: 'money',
        win: 'Your face on every bus stop.',
      ),
      SeasonOpt(
        'vex',
        'Vex (controversial)',
        _big,
        blurb: 'Fame, and a big swing edgy.',
        meter: 8,
        fail: -4,
        odds: 55,
        sig: 20,
        tag: 'fame',
        icon: 'bolt',
        win: 'Banned in two countries. Everybody saw it.',
        lose: 'The campaign was pulled before it ran.',
      ),
    ], art: 'covers'),
    SeasonTab('The off-season.', [
      SeasonOpt(
        'detox',
        'Detox',
        _rest,
        blurb: 'Health.',
        meter: -2,
        stats: {'health': 4},
        icon: 'leaf',
        win: 'No fittings, no diets, no flights.',
      ),
      SeasonOpt(
        'social',
        'Social media push',
        _prep,
        blurb: 'Fame.',
        meter: 3,
        sig: 5,
        tag: 'fame',
        icon: 'phone',
        win: 'A post a day and a lot of new followers.',
      ),
      SeasonOpt(
        'cosmetic',
        'Cosmetic work',
        _push,
        blurb: 'Looks, with a risk.',
        meter: 3,
        odds: 70,
        stats: {'looks': 4},
        hurt: 2,
        icon: 'sparkle',
        win: 'Subtle. Nobody could quite say what changed.',
        lose: 'It went wrong, and the photos are online.',
      ),
    ]),
  ],
  'doctor': [
    SeasonTab('Pick a ward.', [
      SeasonOpt(
        'ae',
        'A&E',
        _push,
        blurb: 'Fast trust, fast burnout.',
        meter: 8,
        odds: 65,
        sig: 15,
        icon: 'hospital',
        win: 'Every kind of emergency, and you kept your head.',
        lose: 'A brutal rotation. You doubted yourself.',
      ),
      SeasonOpt(
        'surgery',
        'Surgery',
        _push,
        blurb: 'Prestige.',
        meter: 10,
        odds: 50,
        sig: 12,
        stats: {'smarts': 2},
        icon: 'cut',
        win: 'The consultant let you close.',
        lose: 'You held retractors for six months.',
      ),
      SeasonOpt(
        'paeds',
        'Paediatrics',
        _prep,
        blurb: 'Kind and calmer.',
        meter: 5,
        sig: 8,
        stats: {'karma': 3},
        icon: 'child',
        win: 'Stickers, small brave patients and grateful parents.',
      ),
    ]),
    SeasonTab('Four patients arrive at once.', [
      SeasonOpt(
        'triage',
        'Triage the rush',
        _big,
        blurb: 'Put them in order. Smarts helps.',
        meter: 12,
        fail: -4,
        sig: 20,
        count: 'lives',
        icon: 'pulse',
        win: 'Chest pain first, the feverish child next. Everyone went home.',
        lose: 'You saw the wrong patient first. It was close.',
      ),
      SeasonOpt(
        'ward',
        'Hold your ward',
        _prep,
        blurb: 'Steady.',
        meter: 5,
        sig: 10,
        icon: 'bed',
        win: 'Corridors full, and your ward held together.',
      ),
    ], art: 'triage'),
    SeasonTab('Research.', [
      SeasonOpt(
        'study',
        'A safe study',
        _prep,
        blurb: 'A paper, slowly.',
        meter: 5,
        sig: 5,
        stats: {'smarts': 1},
        icon: 'notes',
        win: 'A small paper in a solid journal.',
      ),
      SeasonOpt(
        'trial',
        'A bold trial',
        _big,
        blurb: 'A breakthrough with your name on it, or a retraction.',
        meter: 15,
        fail: -6,
        odds: 30,
        sig: 10,
        count: 'papers',
        icon: 'flask',
        win: 'A breakthrough. Your name is on the treatment now.',
        lose: 'The results didn\'t replicate. A retraction.',
      ),
    ]),
    SeasonTab('Review year.', [
      SeasonOpt(
        'holiday',
        'A real holiday',
        _rest,
        blurb: 'Burnout down a lot.',
        meter: -2,
        sig: -40,
        icon: 'sun',
        win: 'A lighter rota and a real holiday.',
      ),
      SeasonOpt(
        'locum',
        'Locum shifts',
        _prep,
        blurb: 'Money, and more burnout.',
        meter: 2,
        sig: 15,
        pay: 6000,
        icon: 'money',
        win: 'Extra shifts at three hospitals. The money is good.',
      ),
    ]),
  ],
  'lawyer': [
    SeasonTab('Three files on your desk.', [
      SeasonOpt(
        'crook',
        'A rich crook',
        _prep,
        blurb: 'A big fee. Ethics down.',
        meter: 4,
        pay: 8000,
        sig: -10,
        icon: 'money',
        win: 'A man in a very good suit paid in advance.',
      ),
      SeasonOpt(
        'probono',
        'Pro bono',
        _prep,
        blurb: 'A wrongful eviction. Ethics up.',
        meter: 4,
        sig: 6,
        stats: {'karma': 4},
        icon: 'heart',
        win: 'A family kept their home because of you.',
      ),
      SeasonOpt(
        'corp',
        'A corporation',
        _prep,
        blurb: 'Steady fees.',
        meter: 5,
        pay: 4000,
        icon: 'building',
        win: 'Contracts, contracts, contracts. Steady fees.',
      ),
    ], art: 'files'),
    SeasonTab('The trial.', [
      SeasonOpt(
        'cross',
        'Cross-examine',
        _big,
        blurb: 'Quiz mini-game: spot the contradiction.',
        meter: 12,
        fail: -5,
        pay: 5000,
        miniGame: 'quiz',
        tag: 'trial',
        icon: 'gavel',
        win: 'You caught the witness in a lie. Verdict in your favour.',
        lose: 'The other side had the better witness.',
      ),
      SeasonOpt(
        'settle',
        'Settle out of court',
        _prep,
        blurb: 'Safe.',
        meter: 3,
        pay: 2000,
        icon: 'handshake',
        win: 'Everybody shook hands and nobody was happy, which is a settlement.',
      ),
    ]),
    SeasonTab('Appeals.', [
      SeasonOpt(
        'precedent',
        'Find the precedent',
        _push,
        blurb: 'Memory mini-game in the law library.',
        meter: 8,
        odds: 55,
        miniGame: 'memory',
        tag: 'trial',
        icon: 'book',
        win: 'A case from 1931 and the higher court agreed.',
        lose: 'The appeal was thrown out in an afternoon.',
      ),
    ]),
    SeasonTab('The review.', [
      SeasonOpt(
        'partner',
        'Go for partner',
        _push,
        blurb: 'Your record and Ethics count.',
        meter: 4,
        odds: 45,
        icon: 'badge',
        win: 'The partners voted you in.',
        lose: 'Not this year, they said.',
      ),
      SeasonOpt(
        'ease',
        'Ease off',
        _rest,
        blurb: 'Fewer hours.',
        meter: -2,
        icon: 'sun',
        win: 'Fewer billable hours and a lot more sleep.',
      ),
    ]),
  ],
  'hustler': [
    SeasonTab('Pick your corner.', [
      SeasonOpt(
        'station',
        'The Station',
        _push,
        blurb: 'Busy, quiet police.',
        meter: 6,
        odds: 70,
        pay: 600,
        tag: 'police:10',
        icon: 'train',
        win: 'Commuters with cash and no time to haggle.',
        lose: 'The rush hour rushed past you.',
      ),
      SeasonOpt(
        'square',
        'The Square',
        _push,
        blurb: 'Busiest, and watched.',
        meter: 8,
        odds: 60,
        pay: 900,
        tag: 'police:35',
        icon: 'square',
        win: 'Tourists by the hundred.',
        lose: 'Slow day on the square.',
      ),
      SeasonOpt(
        'arches',
        'The Arches',
        _push,
        blurb: 'Quiet, cheap, a rival crew.',
        meter: 5,
        odds: 55,
        pay: 400,
        tag: 'police:5',
        icon: 'arch',
        win: 'Your regulars found you.',
        lose: 'The crew under the arches made it clear you weren\'t welcome.',
      ),
      SeasonOpt(
        'market',
        'The Market',
        _prep,
        blurb: 'Steady, with a pitch fee.',
        meter: 4,
        pay: 450,
        icon: 'store',
        win: 'Up at four, a good pitch and a regular crowd.',
      ),
    ], art: 'chalk'),
    SeasonTab('Festival season. How much stock?', [
      SeasonOpt(
        'big',
        'Buy big',
        _big,
        blurb: 'Sell out and make a fortune. Rain, and you\'re stuck.',
        meter: 10,
        fail: -3,
        pay: 2500,
        count: 'sellouts',
        icon: 'tent',
        win: 'Sold out by Saturday afternoon.',
        lose: 'Rain all weekend. You went home with most of it.',
      ),
      SeasonOpt(
        'small',
        'Buy small',
        _push,
        blurb: 'Safe.',
        meter: 5,
        odds: 70,
        pay: 800,
        icon: 'bag',
        win: 'A good weekend, and nothing left over.',
        lose: 'A slow weekend.',
      ),
    ]),
    SeasonTab('A local crew offers protection.', [
      SeasonOpt(
        'pay',
        'Pay up',
        _prep,
        blurb: 'Peace and quiet.',
        meter: 3,
        pay: -500,
        icon: 'money',
        win: 'You paid. Nobody bothered your pitch all autumn.',
      ),
      SeasonOpt(
        'alone',
        'Go it alone',
        _push,
        blurb: 'Keep it all, if they let you.',
        meter: 8,
        odds: 50,
        hurt: 4,
        icon: 'fist',
        win: 'They tested you once and left you alone.',
        lose: 'They kicked your stall over.',
      ),
      SeasonOpt(
        'join',
        'Join them',
        _prep,
        blurb: 'Rep, and a foot in the underworld.',
        meter: 6,
        stats: {'karma': -4},
        icon: 'group',
        win: 'You\'re with them now. Doors open.',
      ),
    ]),
    SeasonTab('Winter.', [
      SeasonOpt(
        'low',
        'Lie low',
        _rest,
        blurb: 'Rest up.',
        meter: -2,
        icon: 'home',
        win: 'You stayed in and let the pitch go quiet.',
      ),
      SeasonOpt(
        'drinks',
        'Sell hot drinks',
        _push,
        blurb: 'On the coldest corner.',
        meter: 4,
        odds: 65,
        pay: 500,
        stats: {'health': -1},
        icon: 'cup',
        win: 'Hot chocolate at the station. A queue every morning.',
        lose: 'Too cold even for hot drinks.',
      ),
    ]),
  ],
  'astronaut': [
    SeasonTab('Selection.', [
      SeasonOpt(
        'centrifuge',
        'The centrifuge',
        _push,
        blurb: 'Breath mini-game. Pass and the countdown moves.',
        meter: 7,
        odds: 55,
        sig: -1,
        miniGame: 'breath',
        icon: 'spin',
        win: 'Nine g and you kept talking. One step closer.',
        lose: 'You greyed out at seven g.',
      ),
      SeasonOpt(
        'systems',
        'Study the systems',
        _prep,
        blurb: 'Smarts.',
        meter: 5,
        stats: {'smarts': 2},
        icon: 'book',
        win: 'You can draw the life-support loop from memory.',
      ),
    ]),
    SeasonTab('Mission training.', [
      SeasonOpt(
        'dock',
        'Docking simulator',
        _push,
        blurb: 'Docking mini-game. Pass and the countdown moves.',
        meter: 8,
        odds: 55,
        sig: -1,
        miniGame: 'docking',
        icon: 'dock',
        win: 'Soft capture on the first try. One step closer.',
        lose: 'You bumped the station. In the simulator, luckily.',
      ),
      SeasonOpt(
        'survival',
        'Survival training',
        _push,
        blurb: 'Cold water and a long walk.',
        meter: 6,
        odds: 65,
        sig: -1,
        stats: {'health': -1},
        icon: 'water',
        win: 'Three days in the forest and nobody quit.',
        lose: 'You were pulled out on day two.',
      ),
    ]),
    SeasonTab('The launch window is open.', [
      SeasonOpt(
        'go',
        'GO',
        _big,
        blurb: 'Launch. Only when the countdown reaches zero.',
        meter: 15,
        fail: -6,
        pay: 5000,
        count: 'flights',
        hurt: 6,
        icon: 'rocket',
        win: 'Main engine cut-off, and the Earth out of the window.',
        lose: 'An abort at two minutes. The capsule came down hard in the sea.',
      ),
      SeasonOpt(
        'scrub',
        'SCRUB',
        _prep,
        blurb: 'Wait for the next window.',
        meter: 2,
        sig: 1,
        icon: 'stop',
        win: 'You scrubbed. Everybody lived to fly another day.',
      ),
    ], art: 'console'),
    SeasonTab('Back on Earth.', [
      SeasonOpt(
        'tour',
        'Public tour',
        _prep,
        blurb: 'Fame.',
        meter: 3,
        tag: 'fame',
        icon: 'mic',
        win: 'School halls full of children who want your job.',
      ),
      SeasonOpt(
        'rest',
        'Quiet recovery',
        _rest,
        blurb: 'Relearn gravity.',
        meter: -1,
        icon: 'home',
        win: 'Relearning gravity, slowly, at home.',
      ),
    ]),
  ],
  'fighter': [
    SeasonTab('Pick your sparring style.', [
      SeasonOpt(
        'striker',
        'Striker',
        _prep,
        blurb: 'Hands and feet.',
        meter: 5,
        stats: {'athleticism': 2},
        icon: 'fist',
        win: 'Pads, bags and a sparring partner who hits back.',
      ),
      SeasonOpt(
        'grappler',
        'Grappler',
        _prep,
        blurb: 'Takedowns and holds.',
        meter: 5,
        stats: {'athleticism': 2},
        icon: 'grapple',
        win: 'Hours on the mat. Your neck is huge now.',
      ),
      SeasonOpt(
        'cardio',
        'Cardio',
        _prep,
        blurb: 'Last all three rounds.',
        meter: 4,
        stats: {'health': 2},
        icon: 'run',
        win: 'Hill sprints until you could go all night.',
      ),
    ]),
    SeasonTab('The weigh-in.', [
      SeasonOpt(
        'cut',
        'Cut weight hard',
        _push,
        blurb: 'An edge, if you don\'t drain yourself.',
        meter: 6,
        odds: 65,
        stats: {'health': -3},
        icon: 'scale',
        win: 'Half a pound under, and you looked huge on the night.',
        lose: 'A bad cut left you drained.',
      ),
      SeasonOpt(
        'talk',
        'Trash-talk',
        _prep,
        blurb: 'Hype. Your opponent is fired up too.',
        meter: 4,
        tag: 'fame',
        icon: 'chat',
        win: 'The press conference went viral.',
      ),
    ]),
    SeasonTab('Fight night. Round by round.', [
      SeasonOpt(
        'strike',
        'Strike',
        _big,
        blurb: 'Beats a grappler.',
        meter: 12,
        fail: -6,
        sig: 8,
        pay: 6000,
        count: 'wins',
        hurt: 5,
        tag: 'strike',
        icon: 'fist',
        win: 'A clean shot in the second round. The crowd was on its feet.',
        lose: 'You lost on points and felt every round the next day.',
      ),
      SeasonOpt(
        'grapple',
        'Grapple',
        _big,
        blurb: 'Beats a defender.',
        meter: 12,
        fail: -6,
        sig: 8,
        pay: 6000,
        count: 'wins',
        hurt: 5,
        tag: 'grapple',
        icon: 'grapple',
        win: 'You took him down and he tapped.',
        lose: 'He kept it standing and picked you apart.',
      ),
      SeasonOpt(
        'defend',
        'Defend',
        _big,
        blurb: 'Beats a striker.',
        meter: 12,
        fail: -6,
        sig: 8,
        pay: 6000,
        count: 'wins',
        hurt: 5,
        tag: 'defend',
        icon: 'shield',
        win: 'He punched himself out and you finished it in the third.',
        lose: 'He walked through your guard.',
      ),
    ], art: 'scorecard'),
    SeasonTab('Recovery.', [
      SeasonOpt(
        'physio',
        'Physio',
        _rest,
        blurb: 'Damage heals slowly.',
        meter: -1,
        sig: -20,
        icon: 'heart',
        win: 'Physio, sleep and nothing harder than a walk.',
      ),
      SeasonOpt(
        'comeback',
        'A quick comeback fight',
        _push,
        blurb: 'Money, and more damage.',
        meter: 5,
        odds: 55,
        sig: 10,
        pay: 3000,
        hurt: 3,
        icon: 'fist',
        win: 'A quick win on a small card.',
        lose: 'You came back too soon.',
      ),
    ]),
  ],
  'vet': [
    SeasonTab('A breech birth at 3 a.m.', [
      SeasonOpt(
        'lamb',
        'Turn the lamb',
        _push,
        blurb: 'Timing mini-game. A farm trusts you more.',
        meter: 8,
        odds: 55,
        miniGame: 'timing',
        icon: 'lamb',
        win: 'Two legs, a head, and a lamb on its feet by dawn.',
        lose: 'A hard night. You lost one.',
      ),
    ]),
    SeasonTab('Summer clinics.', [
      SeasonOpt(
        'free',
        'A free clinic',
        _prep,
        blurb: 'Karma.',
        meter: 4,
        stats: {'karma': 3},
        icon: 'heart',
        win: 'Free jabs for every dog in the village.',
      ),
      SeasonOpt(
        'show',
        'Judge the county show',
        _prep,
        blurb: 'A bit of fame.',
        meter: 4,
        tag: 'fame',
        stats: {'happiness': 2},
        icon: 'trophy',
        win: 'You gave the rosette to a very proud goat.',
      ),
      SeasonOpt(
        'exotic',
        'An exotic case',
        _push,
        blurb: 'A python with a sore throat.',
        meter: 9,
        odds: 50,
        icon: 'snake',
        win: 'The python is fine. You are now the reptile vet.',
        lose: 'You had to call a specialist.',
      ),
    ]),
    SeasonTab('You can reach two farms this harvest.', [
      SeasonOpt(
        'ha',
        'Hollow End and Ash Farm',
        _prep,
        blurb: 'The others lose a heart.',
        meter: 6,
        pay: 1500,
        tag: '0,1',
        icon: 'farm',
        win: 'Long days in the sheds at Hollow End and Ash Farm.',
      ),
      SeasonOpt(
        'kb',
        'Kettle Hill and Brook Lane',
        _prep,
        blurb: 'The others lose a heart.',
        meter: 6,
        pay: 1500,
        tag: '2,3',
        icon: 'farm',
        win: 'Long days on Kettle Hill and down Brook Lane.',
      ),
      SeasonOpt(
        'hb',
        'Hollow End and Brook Lane',
        _prep,
        blurb: 'The others lose a heart.',
        meter: 6,
        pay: 1500,
        tag: '0,3',
        icon: 'farm',
        win: 'Hollow End in the morning, Brook Lane in the afternoon.',
      ),
    ], art: 'farms'),
    SeasonTab('A night call.', [
      SeasonOpt(
        'ditch',
        'A horse in a ditch',
        _big,
        blurb: 'Save it and the whole valley hears.',
        meter: 12,
        fail: -3,
        count: 'rescues',
        icon: 'horse',
        win: 'Midnight, a tractor and a rope. The horse walked home.',
        lose: 'You did everything you could.',
      ),
      SeasonOpt(
        'fire',
        'Stay in by the fire',
        _rest,
        blurb: 'Let the duty vet go.',
        meter: -2,
        icon: 'home',
        win: 'A quiet winter by the fire.',
      ),
    ]),
  ],
  'pilot': [
    SeasonTab('Pick your roster.', [
      SeasonOpt(
        'short',
        'Short-haul',
        _prep,
        blurb: 'Hours, and home every night.',
        meter: 5,
        tag: 'LHR,CDG,AMS,DUB,MAD',
        icon: 'flight',
        win: 'Four sectors a day and your own bed every night.',
      ),
      SeasonOpt(
        'long',
        'Long-haul',
        _push,
        blurb: 'Logbook stamps, and jet lag.',
        meter: 8,
        odds: 75,
        tag: 'NRT,JFK,JNB,SYD,DXB,LAX,GRU',
        stats: {'health': -1},
        icon: 'globe',
        win: 'Tokyo on Tuesday, New York on Friday.',
        lose: 'Jet lag so bad you forgot what day it was.',
      ),
      SeasonOpt(
        'cargo',
        'Cargo nights',
        _prep,
        blurb: 'Night pay.',
        meter: 5,
        pay: 3000,
        tag: 'ANC,LEJ',
        icon: 'box',
        win: 'Night flights full of parcels. Quiet and well paid.',
      ),
    ]),
    SeasonTab('The check ride.', [
      SeasonOpt(
        'check',
        'Fly the simulator',
        _big,
        blurb: 'Docking mini-game: an engine fails on take-off.',
        meter: 10,
        fail: -3,
        miniGame: 'docking',
        count: 'checks',
        icon: 'check',
        win: 'Engine out on take-off and you flew it by the book.',
        lose: 'You failed a section and have to resit.',
      ),
    ]),
    SeasonTab('Peak season: a delay.', [
      SeasonOpt(
        'hold',
        'Hold for late passengers',
        _prep,
        blurb: 'Kind, and the schedule slips.',
        meter: 3,
        stats: {'karma': 2},
        icon: 'group',
        win: 'Twelve passengers made their connection because of you.',
      ),
      SeasonOpt(
        'ontime',
        'Leave on time',
        _push,
        blurb: 'The airline loves it.',
        meter: 7,
        odds: 65,
        icon: 'clock',
        win: 'On time, every time, all summer.',
        lose: 'Delays all summer anyway.',
      ),
    ]),
    SeasonTab('A storm at your destination.', [
      SeasonOpt(
        'push',
        'Push on',
        _big,
        blurb: 'A crosswind landing.',
        meter: 12,
        fail: -6,
        hurt: 2,
        icon: 'wind',
        win: 'A crosswind landing so smooth the cabin clapped.',
        lose: 'A hard landing, and an inquiry.',
      ),
      SeasonOpt(
        'holdpat',
        'Hold',
        _push,
        blurb: 'Fuel ticks down.',
        meter: 5,
        odds: 70,
        icon: 'loop',
        win: 'Two laps of the hold and a gap in the weather.',
        lose: 'You held until fuel made the call for you.',
      ),
      SeasonOpt(
        'divert',
        'Divert',
        _prep,
        blurb: 'Safe and late.',
        meter: 3,
        icon: 'alt',
        win: 'A safe landing, a hundred miles from where they wanted to be.',
      ),
    ], art: 'radar'),
  ],
};

/// The tabs for the career you are in, or null.
List<SeasonTab>? hubTabs(Life l) =>
    hubFor(l) == null ? null : _seasonTabs[l.careerId];

/// Which season tab this year's focus went to, or null.
int? hubSeasonChosen(Life l) =>
    l.hub['focusAge'] == l.age ? l.hub['focus'] as int? : null;

/// What the chosen tab's option was this year, or null.
String? hubSeasonPicked(Life l) =>
    l.hub['focusAge'] == l.age ? l.hub['focusOpt'] as String? : null;

/// The tab's question, with this year's details where it has them.
String hubSeasonHint(Life l, int i) {
  final tabs = hubTabs(l);
  if (tabs == null || i < 0 || i >= tabs.length) return '';
  final now = i == hubBeat(l) ? ' In season: counts for more.' : '';
  final extra = switch ((l.careerId, i)) {
    ('fighter', 2) => ' Tonight: "${fighterFoe(l).$1}", a ${fighterFoe(l).$2}.',
    ('astronaut', 2) =>
      astroCountdown(l) > 0
          ? ' You are T−${astroCountdown(l)}: not on a crew yet.'
          : ' You are on the crew.',
    _ => '',
  };
  return '${tabs[i].prompt}$extra$now';
}

// ---------------- Signature state ----------------

int _hn(Life l, String k, [int d = 0]) => (l.hub[k] as int?) ?? d;

/// Armed forces: boot prints, 0–5.
int fieldFatigue(Life l) => _hn(l, 'fatigue').clamp(0, 5);

/// Athlete: 0–100; over 80 risks injury.
int athleteFatigue(Life l) => _hn(l, 'fatigue').clamp(0, 100);

/// Athlete: the last five results, W/D/L.
List<String> athleteResults(Life l) =>
    List<String>.from(l.hub['results'] as List? ?? const []);

/// Musician: the setlist, newest last: {t, mood, q}.
List<Map<String, dynamic>> setlist(Life l) => [
  for (final s in (l.hub['setlist'] as List?) ?? const [])
    Map<String, dynamic>.from(s as Map),
];

int _bestSong(Life l) =>
    setlist(l).fold(0, (m, s) => max(m, (s['q'] as int?) ?? 0));

/// Actor: roles won by genre, and the type once one leads by 3.
Map<String, int> actorGenres(Life l) => {
  for (final g in const ['Drama', 'Comedy', 'Action', 'Horror'])
    g: ((l.hub['types'] as Map?)?[g] as int?) ?? 0,
};

String? typecast(Life l) {
  final g = actorGenres(l);
  final top = g.entries.reduce((a, b) => b.value > a.value ? b : a);
  return top.value >= 3 ? top.key : null;
}

/// Politician: 0 (conscience) – 100 (whip), 50 in the middle.
int whipBalance(Life l) => _hn(l, 'whip', 50).clamp(0, 100);

/// Model: −50 (wholesome) to 50 (edgy).
int modelImage(Life l) => _hn(l, 'image').clamp(-50, 50);

/// Doctor: 0–100.
int burnout(Life l) => _hn(l, 'burnout').clamp(0, 100);

/// Lawyer: (won, lost, ethics 0–100).
(int, int, int) lawRecord(Life l) =>
    (_hn(l, 'won'), _hn(l, 'lost'), _hn(l, 'ethics', 50).clamp(0, 100));

/// Vet: the four farms and their hearts (0–5).
const vetFarms = ['Hollow End', 'Ash Farm', 'Kettle Hill', 'Brook Lane'];
List<int> farmTrust(Life l) {
  final t = List<int>.from(l.hub['trust'] as List? ?? const [2, 2, 2, 2]);
  return [for (final v in t) v.clamp(0, 5)];
}

/// Pilot: this logbook page's stamps (8 fill it).
List<String> logbook(Life l) =>
    List<String>.from(l.hub['stamps'] as List? ?? const []);

/// Hustler: the corner you worked last.
String? hustlerCorner(Life l) => l.hub['corner'] as String?;

/// Astronaut: years until you are on a crew (0 = ready).
int astroCountdown(Life l) => _hn(l, 'countdown', 3).clamp(0, 3);

/// Fighter: 0–100.
int fightDamage(Life l) => _hn(l, 'damage').clamp(0, 100);

const _foes = [
  ('Iron Reyes', 'grappler', 'grapple'),
  ('Kid Lightning', 'striker', 'strike'),
  ('The Wall', 'defender', 'defend'),
  ('Mad Dog Ortiz', 'striker', 'strike'),
  ('Big Sal', 'grappler', 'grapple'),
  ('Ghost', 'defender', 'defend'),
];

/// Fighter: this year's opponent (name, style word, style id).
(String, String, String) fighterFoe(Life l) =>
    _foes[(l.age * 7 + l.seed) % _foes.length];

// ---------------- Odds and chips ----------------

String? seasonOptLock(Life l, SeasonOpt o) => switch ((l.careerId, o.id)) {
  ('military', 'officer') when l.careerRank < 1 => 'Corporals and up',
  ('musician', 'indie' || 'major' || 'bedroom') when setlist(l).isEmpty =>
    'Write a song first',
  ('astronaut', 'go') when astroCountdown(l) > 0 =>
    'T−${astroCountdown(l)}: not on a crew yet',
  _ when o.pay < 0 && l.money < -o.pay => 'Needs ${_m(-o.pay)}',
  _ => null,
};

int _baseOdds(Life l, SeasonOpt o) {
  final m = hubMeter(l);
  return switch (o.kind) {
    SeasonKind.prep || SeasonKind.rest => 100,
    SeasonKind.push => (o.odds ?? 60) + m ~/ 5,
    SeasonKind.big => (o.odds ?? 35) + m ~/ 2,
  };
}

/// What the career's signature mechanic does to the odds.
int _sigOdds(Life l, SeasonOpt o) {
  if (o.kind == SeasonKind.prep || o.kind == SeasonKind.rest) return 0;
  switch (l.careerId) {
    case 'military':
      return -8 * max(0, fieldFatigue(l) - 2);
    case 'athlete':
      return -max(0, athleteFatigue(l) - 60) ~/ 3;
    case 'musician':
      return (_bestSong(l) - 3) * 8;
    case 'actor':
      final t = typecast(l);
      if (o.tag == null || t == null) return 0;
      return o.tag == t ? 12 : -10;
    case 'politician':
      return o.id == 'debate' ? (50 - (whipBalance(l) - 50).abs()) ~/ 5 : 0;
    case 'police':
      return -dirtyFile(l) * 4;
    case 'model':
      if (o.id == 'luxury') return modelImage(l).abs() < 20 ? 15 : -10;
      if (o.id == 'vex') return modelImage(l) > 0 ? 10 : -5;
      return 0;
    case 'doctor':
      return -max(0, burnout(l) - 60) ~/ 2 +
          (o.id == 'triage' ? l.stats['smarts'] ~/ 5 : 0);
    case 'lawyer':
      return o.id == 'partner' ? (lawRecord(l).$3 - 50) ~/ 5 : 0;
    case 'fighter':
      if (o.tag == null) return -fightDamage(l) ~/ 5;
      final foe = fighterFoe(l).$3;
      const beats = {
        'strike': 'grapple',
        'grapple': 'defend',
        'defend': 'strike',
      };
      return (beats[o.tag] == foe ? 30 : (o.tag == foe ? 5 : -20)) -
          fightDamage(l) ~/ 5;
  }
  return 0;
}

int _odds(Life l, SeasonOpt o, int tab, {double? score}) {
  var odds = _baseOdds(l, o) + _sigOdds(l, o);
  if (l.careerId == 'actor' && o.id == 'bold') odds += l.stats['looks'] ~/ 4;
  if (score != null) odds += ((score - 0.5) * 50).round();
  if (tab == hubBeat(l) && o.kind != SeasonKind.prep) odds += 5;
  return odds.clamp(5, 95);
}

/// How the odds look to the player: never a number.
String _oddsWord(int odds) => odds >= 75
    ? 'Likely'
    : odds >= 55
    ? 'Fair chance'
    : odds >= 35
    ? 'Risky'
    : 'Long shot';

/// The option's chips: (text, tone) with tone 1 good, −1 a risk, 0 neutral.
List<(String, int)> seasonChips(Life l, SeasonOpt o, int tab) {
  final spec = hubFor(l);
  final meter = spec?.meter ?? 'Meter';
  final out = <(String, int)>[];
  if (o.meter != 0) {
    out.add((
      '$meter ${o.meter > 0 ? '+' : '−'}${o.meter.abs()}',
      o.meter > 0 ? 1 : -1,
    ));
  }
  for (final e in o.stats.entries) {
    if (!Stats.visible.contains(e.key) && e.key != 'karma') continue;
    final n = '${e.key[0].toUpperCase()}${e.key.substring(1)}';
    out.add((
      '$n ${e.value > 0 ? '+' : '−'}${e.value.abs()}',
      e.value > 0 ? 1 : -1,
    ));
  }
  if (o.pay > 0) out.add(('+${_m(o.pay)}', 1));
  if (o.pay < 0) out.add(('Costs ${_m(-o.pay)}', -1));
  if (o.count != null) out.add((_countWord(o.count!), 1));
  final sig = _sigChip(l, o);
  if (sig != null) out.add(sig);
  if (o.miniGame != null) out.add(('Mini-game', 0));
  if (o.kind == SeasonKind.push || o.kind == SeasonKind.big) {
    final odds = _odds(l, o, tab);
    out.add((_oddsWord(odds), odds >= 55 ? 0 : -1));
  }
  if (o.hurt > 0) out.add(('Injury risk', -1));
  return out;
}

String _countWord(String key) => switch (key) {
  'medals' => 'Medal',
  'badges' => 'Badge',
  'commendations' => 'Commendation',
  'rescues' => 'A rescue',
  'titles' => 'Trophy',
  'hits' => 'A hit',
  'tours' => 'Encore',
  'awards' => 'Award',
  'shows' => 'Shows',
  'lives' => 'Lives saved',
  'papers' => 'A paper',
  'sellouts' => 'Sell-out',
  'flights' => 'A flight',
  'wins' => 'Win',
  'checks' => 'Check passed',
  _ => key,
};

(String, int)? _sigChip(Life l, SeasonOpt o) {
  final s = o.sig;
  switch (l.careerId) {
    case 'military':
      if (s > 0) return ('Fatigue +$s', -1);
      if (s < 0) return ('Clears Fatigue', 1);
    case 'athlete':
      if (s > 0) return ('Fatigue +$s', s >= 10 ? -1 : 0);
      if (s < 0) return ('Fatigue −${-s}', 1);
    case 'politician':
      if (s > 0) return ('Whip +', 0);
      if (s < 0) return ('Conscience +', 0);
    case 'police':
      if (s > 0) return ('Dirty file', -1);
    case 'model':
      if (s > 0) return ('Image: edgy', 0);
      if (s < 0) return ('Image: wholesome', 0);
    case 'doctor':
      if (s > 0) return ('Burnout +$s', -1);
      if (s < 0) return ('Burnout −${-s}', 1);
    case 'lawyer':
      if (s > 0) return ('Ethics +$s', 1);
      if (s < 0) return ('Ethics −${-s}', -1);
    case 'astronaut':
      if (s < 0) return ('Countdown −1', 1);
    case 'fighter':
      if (s > 0) return ('Damage +$s', -1);
      if (s < 0) return ('Damage −${-s}', 1);
    case 'musician' when o.tag != null && o.miniGame != null:
      return ('New song', 1);
    case 'actor' when o.tag != null && o.miniGame != null:
      final t = typecast(l);
      if (t == null) return null;
      return o.tag == t ? ('Your type', 1) : ('Off-type', -1);
    case 'pilot' when o.tag != null:
      return ('Stamp', 1);
    case 'vet' when o.tag != null && o.tag!.contains(','):
      return ('Two farms trust you', 1);
  }
  return null;
}

// ---------------- Doing it ----------------

/// Moves the career's meter. Musicians grow listeners and police close
/// cases, because their meters are worked out from those.
String? _seasonMeter(Life l, int by) {
  l.hub['active'] = l.age;
  switch (l.careerId) {
    case 'musician':
      final fans = listenersOf(l);
      final change = by >= 0
          ? max(40 * by, fans * by ~/ 40)
          : -(fans * by.abs() ~/ 60);
      l.music['fans'] = max(0, fans + change);
      _notePeak(l);
      return change == 0
          ? null
          : 'Listeners ${change > 0 ? '+' : '−'}${change.abs()}';
    case 'police':
      if (by < 10) return null;
      final closed = casesClosed(l) + 1;
      l.marks
        ..removeWhere((m) => m.startsWith('cop_closed:'))
        ..add('cop_closed:$closed');
      _notePeak(l);
      return 'Cases closed +1';
    default:
      if (by == 0) return null;
      return _meterNote(l, by);
  }
}

const _songs = {
  'love': ['Paper Hearts', 'Slow Dance', 'Your Coat', 'Kitchen Light'],
  'anthem': ['Neon Rain', 'All of Us', 'Hold the Line', 'Bright Side'],
  'protest': ['Sirens', 'Not in Our Name', 'Landlord Blues', 'Whose Streets'],
  'heartbreak': ['Last Bus Home', 'Empty Side', 'Ghost Town', 'Two Coffees'],
};

/// The career's signature mechanic after a pick; returns notes.
List<String> _sigApply(
  Life l,
  Random rng,
  int tab,
  SeasonOpt o,
  bool won,
  double? score,
) {
  final notes = <String>[];
  void add(String k, int by, int lo, int hi, [int d = 0]) =>
      l.hub[k] = (_hn(l, k, d) + by).clamp(lo, hi);
  switch (l.careerId) {
    case 'military':
      add('fatigue', o.sig, 0, 5);
      if (o.sig != 0) notes.add('Fatigue ${fieldFatigue(l)}/5');
      if (o.id == 'officer' && won) l.hub['officer'] = true;
      if (tab == 2) {
        for (final n in l.npcs.where((n) => n.alive && n.circle == 'Family')) {
          n.addBond(-3);
        }
        notes.add('A letter from home · family bonds −3');
      }
      if (o.tag == 'family') {
        for (final n in l.npcs.where((n) => n.alive && n.circle == 'Family')) {
          n.addBond(3);
        }
        notes.add('Family bonds +3');
      }
    case 'athlete':
      add('fatigue', o.sig, 0, 100);
      if (o.sig != 0) notes.add('Fatigue ${athleteFatigue(l)}');
      if (tab == 1 && o.id == 'play') {
        final res = [
          ...athleteResults(l),
          for (var i = 0; i < 3; i++)
            rng.nextInt(100) < (won ? 65 : 30)
                ? 'W'
                : (rng.nextBool() ? 'D' : 'L'),
        ];
        l.hub['results'] = res.sublist(max(0, res.length - 5));
      }
      if (o.tag == 'raise' && won) {
        l.salary = (l.salary * 1.2).round();
        notes.add('Salary +20%');
      }
      if (o.sig > 0 && athleteFatigue(l) >= 80 && rng.nextInt(100) < 40) {
        l.stats.add('health', -8);
        notes.add(_meterNote(l, -6));
        notes.add('Injured · Health −8');
        _log(l, 'injured through overtraining');
      }
    case 'musician':
      if (o.tag != null && _songs.containsKey(o.tag)) {
        final names = _songs[o.tag]!;
        final have = setlist(l).map((s) => s['t']).toSet();
        final name = names.firstWhere(
          (n) => !have.contains(n),
          orElse: () => '${names[rng.nextInt(names.length)]} II',
        );
        final q = (score != null ? 1 + (score * 4).round() : 2 + rng.nextInt(3))
            .clamp(1, 5);
        final list = [
          ...setlist(l),
          {'t': name, 'mood': o.tag, 'q': q},
        ];
        l.hub['setlist'] = list.sublist(max(0, list.length - 6));
        notes.add('"$name" ${'★' * q}${'☆' * (5 - q)}');
      }
      if (tab == 1 && o.tag != null) {
        final list = setlist(l);
        if (list.isNotEmpty) {
          final up = int.parse(o.tag!);
          list.last['q'] = ((list.last['q'] as int) + up).clamp(1, 5);
          l.hub['setlist'] = list;
          notes.add('"${list.last['t']}" ${'★' * (list.last['q'] as int)}');
        }
      }
    case 'actor':
      if (o.tag == 'stars') {
        final stars = won ? 4 + rng.nextInt(2) : 1 + rng.nextInt(2);
        l.hub['stars'] = stars;
        notes.add('Reviews ${'★' * stars}${'☆' * (5 - stars)}');
      } else if (o.tag != null && won) {
        final g = Map<String, dynamic>.from(l.hub['types'] as Map? ?? {});
        g[o.tag!] = ((g[o.tag!] as int?) ?? 0) + 1;
        l.hub['types'] = g;
        final t = typecast(l);
        if (t != null) notes.add('Typecast: $t');
      }
    case 'politician':
      add('whip', o.sig, 0, 100, 50);
      final w = whipBalance(l);
      if (o.sig != 0) notes.add(w >= 50 ? 'Whip $w' : 'Conscience ${100 - w}');
      if (w < 20 && o.sig < 0) notes.add(_meterNote(l, -3));
      if (w < 20 && o.sig < 0) notes.add('The whip is furious');
      if (w > 80 && o.sig > 0) {
        l.performance = min(100, l.performance + 5);
        notes.add('The whip owes you');
      }
    case 'police':
      if (o.sig > 0) {
        addDirtyFile(l, o.sig);
        notes.add('Your file: ${dirtyFile(l)} marks');
      }
    case 'model':
      add('image', o.sig, -50, 50);
      if (o.sig != 0) {
        final i = modelImage(l);
        notes.add(
          i > 15
              ? 'Image: edgy'
              : i < -15
              ? 'Image: wholesome'
              : 'Image: balanced',
        );
      }
    case 'doctor':
      add('burnout', o.sig, 0, 100);
      if (o.sig != 0) notes.add('Burnout ${burnout(l)}%');
      if (o.sig > 0 && burnout(l) > 80 && rng.nextInt(100) < 30) {
        notes.add(_meterNote(l, -6));
        notes.add('A mistake on the ward');
      }
    case 'lawyer':
      add('ethics', o.sig, 0, 100, 50);
      if (o.sig != 0) notes.add('Ethics ${lawRecord(l).$3}');
      if (o.tag == 'trial') {
        l.hub[won ? 'won' : 'lost'] = _hn(l, won ? 'won' : 'lost') + 1;
        final (w, ls, _) = lawRecord(l);
        notes.add('Record $w–$ls');
      }
    case 'hustler':
      if (tab == 0) l.hub['corner'] = o.id;
      final police = o.tag != null && o.tag!.startsWith('police:')
          ? int.parse(o.tag!.substring(7))
          : 0;
      if (police > 0 && rng.nextInt(100) < police) {
        l.money -= 200;
        notes.add('Moved on by police · −${_m(200)}');
      }
    case 'astronaut':
      if (o.sig < 0 && won) add('countdown', -1, 0, 3, 3);
      if (o.sig > 0) add('countdown', o.sig, 0, 3, 3);
      if (o.id == 'go') add('countdown', 3, 0, 3, 3);
      notes.add(
        astroCountdown(l) == 0
            ? 'On the crew'
            : 'Countdown T−${astroCountdown(l)}',
      );
    case 'fighter':
      add('damage', won || o.sig < 0 ? o.sig : o.sig * 2, 0, 100);
      if (o.sig != 0) notes.add('Damage ${fightDamage(l)}');
      if (fightDamage(l) >= 80 && o.sig > 0) {
        l.stats.add('health', -4);
        notes.add('The doctors want you to stop');
      }
    case 'vet':
      final t = farmTrust(l);
      if (o.tag != null && o.tag!.contains(',')) {
        final pick = o.tag!.split(',').map(int.parse).toSet();
        for (var i = 0; i < 4; i++) {
          t[i] = (t[i] + (pick.contains(i) ? 1 : -1)).clamp(0, 5);
        }
        notes.add(
          'Farm trust up: ${[for (final i in pick) vetFarms[i]].join(' and ')}',
        );
      } else if (won && o.kind != SeasonKind.rest) {
        final i = rng.nextInt(4);
        t[i] = (t[i] + 1).clamp(0, 5);
        notes.add('${vetFarms[i]} trust +1');
      }
      l.hub['trust'] = t;
    case 'pilot':
      if (o.tag != null && won) {
        final codes = o.tag!.split(',');
        final have = logbook(l);
        final fresh = codes.where((c) => !have.contains(c)).toList();
        final code = fresh.isEmpty
            ? codes[rng.nextInt(codes.length)]
            : fresh[rng.nextInt(fresh.length)];
        if (!have.contains(code)) {
          final page = [...have, code];
          notes.add('Logbook stamp: $code');
          if (page.length >= 8) {
            l.money += 5000;
            l.stats.add('happiness', 5);
            notes.add(
              'A full page: bonus ${_m(5000)} and a staff-travel holiday',
            );
            l.hub['stamps'] = <String>[];
            l.hub['pages'] = _hn(l, 'pages') + 1;
          } else {
            l.hub['stamps'] = page;
          }
        }
      }
  }
  return notes;
}

/// Runs one season choice: the year's focus.
ActionResult hubSeasonPick(
  Life l,
  Random rng,
  int tab,
  SeasonOpt o, {
  double? score,
}) {
  final spec = hubFor(l);
  if (spec == null) return ActionResult('There is nothing to focus on here.');
  final inSeason = tab == hubBeat(l);
  l.hub
    ..['focus'] = tab
    ..['focusOpt'] = o.id
    ..['focusAge'] = l.age;
  final odds = _odds(l, o, tab, score: score);
  final won = rng.nextInt(100) < odds;
  final deltas = Map<String, int>.of(o.stats);
  final notes = <String>[];
  var text = won ? o.win : (o.lose.isEmpty ? o.win : o.lose);
  int by;
  if (won) {
    by = o.meter + (inSeason && o.meter > 0 ? 3 : 0);
    if (o.kind != SeasonKind.rest && o.meter > 0) {
      l.performance = min(100, l.performance + max(2, o.meter ~/ 2));
    }
    if (o.count != null) _add(l, o.count!);
    if (o.kind == SeasonKind.big) {
      _log(l, '${spec.seasons[tab].toLowerCase()}: ${o.label.toLowerCase()}');
    }
    if (o.tag == 'fame') {
      l.fame = min(100, l.fame + 3);
      notes.add('Fame +3');
    }
  } else {
    by =
        o.fail ??
        switch (o.kind) {
          SeasonKind.big => -5,
          _ => 2,
        };
    if (o.hurt > 0) deltas['health'] = (deltas['health'] ?? 0) - o.hurt;
    if (o.kind == SeasonKind.big) {
      deltas['happiness'] = (deltas['happiness'] ?? 0) - 3;
    }
  }
  if (o.kind == SeasonKind.rest && inSeason) {
    deltas['happiness'] = (deltas['happiness'] ?? 0) + 2;
  }
  if (spec.id == 'military' && o.id == 'assault' && won) {
    l.fitness = min(100, l.fitness + 3);
  }
  final r = statChange(l, text, deltas);
  notes.addAll(r.notes);
  if (_seasonMeter(l, by) case final n?) notes.add(n);
  final pay = o.pay > 0
      ? (won ? o.pay * (o.kind == SeasonKind.big ? l.careerRank + 1 : 1) : 0)
      : o.pay;
  if (pay != 0) {
    l.money += pay;
    notes.add(pay > 0 ? 'Money +${_m(pay)}' : 'Money −${_m(-pay)}');
  }
  notes.addAll(_sigApply(l, rng, tab, o, won, score));
  if (inSeason) notes.add('In season');
  text = text.isEmpty ? '${o.label}.' : text;
  return ActionResult(text, notes);
}

/// The choice as an activity, so it costs energy, goes in the feed, plays
/// its mini-game and saves like any other.
GameAction hubSeasonAction(Life l, int tab, SeasonOpt o) {
  final spec = hubFor(l);
  final name = spec == null ? o.label : '${spec.seasons[tab]}: ${o.label}';
  return GameAction(
    id: 'hub_season_$tab',
    label: name,
    category: 'Career',
    keywords: const ['season', 'focus'],
    miniGame: o.miniGame,
    extraCheck: (l) {
      final s = hubFor(l);
      if (s == null || hubTabs(l) == null) return 'Only in a special career';
      final chosen = hubSeasonChosen(l);
      if (chosen != null) {
        return 'This year\'s focus: ${s.seasons[chosen]}. Pick again next year.';
      }
      return seasonOptLock(l, o);
    },
    run: (l, rng) => hubSeasonPick(l, rng, tab, o),
    scored: o.miniGame == null
        ? null
        : (l, rng, score) => hubSeasonPick(l, rng, tab, o, score: score),
  );
}
