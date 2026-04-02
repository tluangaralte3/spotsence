// lib/screens/home/visitor_guide_screen.dart
//
// Visitor Guide — Dos & Don'ts per NE Indian state.
// Accessed from the Home screen's "Visitor Guide" card.
// State content is fully static for offline reliability.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model + content
// ─────────────────────────────────────────────────────────────────────────────

class _StateGuide {
  final String stateName;
  final String emoji;
  final String tagline;
  final String about;
  final List<String> dos;
  final List<String> donts;
  final List<_QuickFact> facts;

  const _StateGuide({
    required this.stateName,
    required this.emoji,
    required this.tagline,
    required this.about,
    required this.dos,
    required this.donts,
    required this.facts,
  });
}

class _QuickFact {
  final IconData icon;
  final String label;
  final String value;
  const _QuickFact(this.icon, this.label, this.value);
}

// ── State guide content ───────────────────────────────────────────────────────

const Map<String, _StateGuide> _kGuides = {
  'Mizoram': _StateGuide(
    stateName: 'Mizoram',
    emoji: '🏔️',
    tagline: 'Land of the Blue Mountains',
    about:
        'Mizoram is a small, hilly state tucked in the southernmost corner of Northeast India. '
        'Known for its breathtaking mountain scenery, the warm and welcoming Mizo people, and one '
        'of India\'s highest literacy rates. Aizawl, the capital, clings to a dramatic ridge at '
        '1,300 m. The state is famous for its vibrant bamboo culture, bamboo dances (Cheraw), and '
        'the annual Chapchar Kut festival. Christianity is central to daily life and community events.',
    dos: [
      'Remove footwear before entering homes, churches, and many local shops',
      'Dress modestly — long pants/skirts and covered shoulders, especially in villages',
      'Greet elders respectfully; the community values hierarchy and politeness',
      'Carry an Inner Line Permit (ILP) — required for all non-Mizoram residents',
      'Carry enough cash; ATMs are scarce outside Aizawl',
      'Try local staples: Bai (vegetable stew), Sawhchiar (rice porridge), and Vawksa Rep (smoked pork)',
      'Book accommodation in advance during Chapchar Kut (March) and New Year',
      'Hire certified local guides for jungle treks and remote trails',
      'Respect Sunday as a day of rest — most shops and activities close',
    ],
    donts: [
      'Don\'t consume alcohol in prohibited zones; Mizoram has dry laws in many areas',
      'Don\'t litter — Mizo communities take extreme pride in cleanliness',
      'Don\'t photograph people, ceremonies, or churches without explicit permission',
      'Don\'t wear revealing or immodest clothing in villages and religious spaces',
      'Don\'t hunt, trap, or harm wildlife — strict conservation laws apply',
      'Don\'t enter restricted forest areas without proper permits',
      'Don\'t underestimate mountain roads — always travel in daylight',
      'Don\'t skip the ILP formality — fines and deportation are enforced',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~1.1 Million'),
      _QuickFact(Icons.language, 'Language', 'Mizo, English'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – Mar'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'Yes'),
    ],
  ),

  'Manipur': _StateGuide(
    stateName: 'Manipur',
    emoji: '💎',
    tagline: 'Jewel of India',
    about:
        'Manipur, aptly called the "Jewel of India", is home to the pristine Loktak Lake — '
        'Asia\'s largest freshwater lake — the floating phumdis, and the famous Sangai deer. '
        'The classical Manipuri dance (Ras Lila) and the Ima Keithel (all-women\'s market) in '
        'Imphal are cultural icons. Diverse ethnic communities, ancient polo fields, and the '
        'stunning Dzüko Valley make Manipur a truly unique destination.',
    dos: [
      'Obtain an Inner Line Permit (ILP) or Protected Area Permit (PAP) before arriving',
      'Visit Loktak Lake early morning for floating phumdis and bird watching',
      'Try authentic cuisine: Eromba (fermented fish chutney), Singju (salad), and Chamthong',
      'Attend the Sangai Festival (November) — a showcase of Manipur\'s art and culture',
      'Respect the Ima Keithel — the world\'s only all-women\'s market',
      'Dress conservatively, especially near sacred sites and in villages',
      'Follow all security advisories issued by the local administration',
      'Hire local guides for trekking; terrain can be complex and restricted',
    ],
    donts: [
      'Don\'t enter restricted or sensitive zones without the proper permits',
      'Don\'t photograph military installations, checkpoints, or security personnel',
      'Don\'t disrespect local traditions, the Meitei Mayek script, or religious practices',
      'Don\'t ignore official curfew or bandh (shutdown) notices',
      'Don\'t travel on unfamiliar rural roads after dark',
      'Don\'t leave your permit or ID behind — checkpoints are frequent',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~3.2 Million'),
      _QuickFact(Icons.language, 'Language', 'Meitei, English'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – Mar'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'Yes'),
    ],
  ),

  'Meghalaya': _StateGuide(
    stateName: 'Meghalaya',
    emoji: '☁️',
    tagline: 'Abode of Clouds',
    about:
        'Meghalaya holds the world record for the wettest place on Earth '
        '(Mawsynram and Cherrapunji). Made famous by its extraordinary living root bridges — '
        'grown over centuries from the roots of rubber fig trees — crystal-clear rivers, '
        'deep limestone caves, and rolling green hills. The state follows a matrilineal society '
        'tradition, and its people (Khasi, Jaintia, Garo) have vibrant festivals and unique customs.',
    dos: [
      'Pack rain gear regardless of season — sudden downpours are common year-round',
      'Hire experienced local guides for cave exploration (Shnongpdeng, Mawsmai)',
      'Take off shoes when entering village longhouses and designated sacred areas',
      'Try local food: Jadoh (rice with meat), Tungrymbai (fermented soybean), Dohneiiong',
      'Respect the matrilineal customs — property and surnames pass through the mother',
      'Visit during October to April for clearer skies and best trekking conditions',
      'Book living root bridge treks in advance — some require overnight stays',
      'Support local homestays over large hotels for authentic experiences',
    ],
    donts: [
      'Don\'t touch or damage the living root bridges — they are centuries old and irreplaceable',
      'Don\'t litter in rivers, caves, or forests — eco-sensitivity is paramount',
      'Don\'t photograph sacred groves (Law Kyntang) or sacred spaces without permission',
      'Don\'t engage in unauthorized mining, rock collection, or sand extraction',
      'Don\'t underestimate the trekking terrain — steep, slippery, and remote',
      'Don\'t let children or non-swimmers near forceful river currents',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~3.4 Million'),
      _QuickFact(Icons.language, 'Language', 'Khasi, English, Garo'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – Apr'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'No'),
    ],
  ),

  'Assam': _StateGuide(
    stateName: 'Assam',
    emoji: '🦏',
    tagline: 'Gateway to the Northeast',
    about:
        'Assam is the beating heart of Northeast India — home to the world-famous Assam CTC '
        'and Orthodox tea, the endangered one-horned rhinoceros in Kaziranga National Park, '
        'and the mighty Brahmaputra river. The Bihu festival (April, October, January) brings '
        'the whole state alive with folk music and dance. Assam\'s cuisine, silk (Muga and Eri), '
        'and warm hospitality make it a must-visit.',
    dos: [
      'Book wildlife safaris at Kaziranga (elephant and jeep) well in advance, Oct–Apr only',
      'Try Assam tea at estate-run tea gardens for the freshest experience',
      'Attend the Bihu festival — Bohag Bihu (April) is the most vibrant',
      'Taste local specialties: Masor Tenga (sour fish curry), Khar, Pitha rice cakes',
      'Carry mosquito repellent for any travel to wildlife or wetland areas',
      'Respect Kamakhya Temple dress code — cover shoulders and legs',
      'Hire certified naturalists for wildlife experiences in national parks',
    ],
    donts: [
      'Don\'t feed, approach, or disturb wildlife inside national parks',
      'Don\'t enter tiger reserves without an authorized guide',
      'Don\'t litter in tea gardens — most have strict cleanliness rules',
      'Don\'t ignore flood warnings during monsoon (June–September)',
      'Don\'t disrespect the sacredness of Kamakhya Temple and similar sites',
      'Don\'t visit Kaziranga outside the open season (park closes May–Oct)',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~35 Million'),
      _QuickFact(Icons.language, 'Language', 'Assamese, Bengali'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Nov – Apr'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'No'),
    ],
  ),

  'Nagaland': _StateGuide(
    stateName: 'Nagaland',
    emoji: '🦅',
    tagline: 'Land of Festivals',
    about:
        'Nagaland is a land of warrior traditions, vibrant tribal cultures, and soaring mountain '
        'landscapes. With 16 major tribes each having unique attire, language, and customs, the '
        'state offers a truly immersive cultural experience. The Hornbill Festival (Dec 1–10) '
        'in Kisama is a spectacular celebration of Naga heritage. Kohima, with its famous '
        'WWII war cemetery, carries deep historical significance.',
    dos: [
      'Obtain an Inner Line Permit (ILP) — mandatory for all non-Nagaland residents',
      'Attend the Hornbill Festival (December 1–10) for an unmatched cultural experience',
      'Try smoked pork with bamboo shoots, Axone (fermented soybean), and local rice beer (Zutho)',
      'Dress modestly — Christianity is central; respect church services and dress codes',
      'Ask for permission before photographing tribal people, ceremonies, or villages',
      'Learn a few words in Nagamese — it will be warmly appreciated',
      'Use registered local guides for off-track treks and tribal village visits',
    ],
    donts: [
      'Don\'t enter tribal villages uninvited — always seek permission from the village council',
      'Don\'t disrespect local Christian practices, Sunday worship, or festivals',
      'Don\'t carry weapons or illegal items — checkpoints are thorough',
      'Don\'t venture off established roads without a guide — terrain is rugged',
      'Don\'t photograph funerals, war memorials disrespectfully, or restricted zones',
      'Don\'t discard non-biodegradable waste in natural areas',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~2.2 Million'),
      _QuickFact(Icons.language, 'Language', 'Nagamese, English'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – May'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'Yes'),
    ],
  ),

  'Tripura': _StateGuide(
    stateName: 'Tripura',
    emoji: '🏛️',
    tagline: 'Culture & Heritage of the East',
    about:
        'Tripura is one of the most accessible Northeast states, connected to the rest of India '
        'by rail, road, and air. It is known for the stunning Unakoti rock carvings (dating to '
        'the 8th–9th century), the Neermahal water palace, Ujjayanta Palace, and the diverse '
        'tribal cultures of the Tripuri, Reang, and Chakma peoples. Bengali culture blends '
        'seamlessly with indigenous traditions.',
    dos: [
      'Visit Unakoti — one of India\'s most underrated archaeological wonders',
      'Try local street food: Mui Borok (rice-based dishes), Chakhwi, and Bengali sweets',
      'Hire local guides for jungle treks to Jampui Hills and Trishna Wildlife Sanctuary',
      'Carry cash for remote areas — digital payments are limited outside Agartala',
      'Explore Neermahal (water palace) during calm weather for boat rides',
      'Respect Buddhist monasteries — dress modestly and remove footwear',
    ],
    donts: [
      'Don\'t photograph inside temples or sacred sites without asking permission',
      'Don\'t travel alone at night in remote or forest areas',
      'Don\'t litter at heritage sites — Unakoti especially requires respectful behavior',
      'Don\'t disrespect religious practices of both Hindu and Buddhist communities',
      'Don\'t carry large amounts of cash — use bank branches in Agartala city',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~4 Million'),
      _QuickFact(Icons.language, 'Language', 'Bengali, Kokborok'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – Mar'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'No'),
    ],
  ),

  'Arunachal': _StateGuide(
    stateName: 'Arunachal Pradesh',
    emoji: '🌄',
    tagline: 'Land of the Dawn-Lit Mountains',
    about:
        'Arunachal Pradesh is India\'s largest Northeastern state and one of its most pristine. '
        'The state greets the sun first in India and is home to Tawang Monastery (the largest '
        'in India and second largest in Asia), the Sela Pass, roaring rivers ideal for white-water '
        'rafting, and over 26 major tribes. Its rich biodiversity and remote wilderness make '
        'it a paradise for eco-adventurers.',
    dos: [
      'Obtain an Inner Line Permit (ILP) — strictly enforced at multiple checkpoints',
      'Acclimatize gradually before ascending to high-altitude destinations like Tawang (3,000+ m)',
      'Respect Buddhist monastery etiquette — remove shoes, cover head if asked, no loud voices',
      'Try local food: Thukpa (noodle soup), Apong (rice beer), Pika Pila, and Bamboo shoot dishes',
      'Carry warm clothing even in summer — temperatures drop sharply at altitude',
      'Book certified operators for river rafting, trekking, and adventure sports',
      'Keep permits accessible — you may be checked multiple times along the way',
    ],
    donts: [
      'Don\'t visit without the required ILP — checkpoints are strict and fines are high',
      'Don\'t photograph border areas, military installations, or disputed territory zones',
      'Don\'t disturb the protected wildlife in Namdapha or Pakke Tiger Reserves',
      'Don\'t underestimate altitude sickness — ascend slowly and carry medication',
      'Don\'t venture into restricted border zones near China or Myanmar',
      'Don\'t disrespect local animist and Buddhist beliefs and practices',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~1.7 Million'),
      _QuickFact(Icons.language, 'Language', 'English, Nyishi, Adi'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Oct – Apr'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'Yes'),
    ],
  ),

  'Sikkim': _StateGuide(
    stateName: 'Sikkim',
    emoji: '🏔️',
    tagline: 'India\'s First Organic State',
    about:
        'Sikkim is a tiny Himalayan gem bordered by Nepal, Tibet, and Bhutan. '
        'It is India\'s first fully organic state and home to the world\'s third-highest peak, '
        'Kangchenjunga. Gangtok, the capital, offers stunning mountain views, vibrant monasteries '
        '(Rumtek, Pemayangtse), and quirky café culture. Sikkim is celebrated for its strict '
        'environmental laws, immaculate cleanliness, and unique blend of Nepali, Lepcha, '
        'and Tibetan cultures.',
    dos: [
      'Obtain ILP/PAP for North Sikkim (Yumthang, Zero Point) — mandatory for all visitors',
      'Respect monastery protocols: remove shoes, dress modestly, no photography in prayer halls',
      'Try local food: Momos, Thukpa, Sel Roti, Gundruk, and Chang (traditional millet beer)',
      'Buy organic products — Sikkim\'s certified organic produce is a unique souvenir',
      'Acclimatize properly before ascending to high-altitude areas (Nathula, Gurudongmar)',
      'Use registered/government-approved guides for treks',
      'Carry a valid ID — permit checks are frequent',
    ],
    donts: [
      'Don\'t bring or use plastic bags — they are banned in Sikkim; violators are fined',
      'Don\'t litter anywhere — Sikkim has some of India\'s strictest environmental enforcement',
      'Don\'t eat non-vegetarian food inside monasteries or their premises',
      'Don\'t photograph locals, monks, or ceremonies without asking first',
      'Don\'t skip altitude sickness precautions — Gurudongmar is at 5,430 m',
      'Don\'t engage in unauthorized trekking in restricted zones',
      'Don\'t disturb the high-altitude ecosystem — stay on marked trails',
    ],
    facts: [
      _QuickFact(Icons.people_outline, 'Population', '~660,000'),
      _QuickFact(Icons.language, 'Language', 'Nepali, Sikkimese, English'),
      _QuickFact(Icons.wb_sunny_outlined, 'Best Time', 'Mar–May, Oct–Dec'),
      _QuickFact(Icons.card_travel_outlined, 'ILP Required', 'Partial'),
    ],
  ),
};

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class VisitorGuideScreen extends StatelessWidget {
  final String stateName;
  const VisitorGuideScreen({super.key, required this.stateName});

  @override
  Widget build(BuildContext context) {
    // Arunachal is stored under the abbreviation key 'Arunachal'
    final key = stateName == 'Arunachal Pradesh' ? 'Arunachal' : stateName;
    final guide = _kGuides[key];

    if (guide == null) {
      return _ComingSoonScreen(stateName: stateName);
    }

    return Scaffold(
      backgroundColor: context.col.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: context.col.bg,
            leading: IconButton(
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.col.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: context.col.textPrimary,
                  size: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.secondary.withOpacity(0.25),
                      AppColors.primary.withOpacity(0.15),
                      context.col.bg,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Text(guide.emoji,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 8),
                        Text(
                          guide.stateName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          guide.tagline,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick facts row
                _QuickFactsRow(facts: guide.facts)
                    .animate()
                    .fadeIn(duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 20),

                // About
                _GuideCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.info,
                  title: 'About ${guide.stateName}',
                  child: Text(
                    guide.about,
                    style: TextStyle(
                      color: context.col.textSecondary,
                      fontSize: 14,
                      height: 1.65,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 80.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Dos
                _GuideCard(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: AppColors.success,
                  title: 'What To Do ✅',
                  child: _BulletList(
                    items: guide.dos,
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 160.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // Don'ts
                _GuideCard(
                  icon: Icons.cancel_outlined,
                  iconColor: AppColors.error,
                  title: 'What Not To Do 🚫',
                  child: _BulletList(
                    items: guide.donts,
                    color: AppColors.error,
                    icon: Icons.cancel_rounded,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 240.ms, duration: 300.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Footer note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.accent, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Always check the latest travel advisories and permit requirements '
                          'before your trip. Local rules may vary by district and season.',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 320.ms, duration: 300.ms),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Coming soon screen for states without content yet
// ─────────────────────────────────────────────────────────────────────────────

class _ComingSoonScreen extends StatelessWidget {
  final String stateName;
  const _ComingSoonScreen({required this.stateName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.col.bg,
      appBar: AppBar(
        backgroundColor: context.col.bg,
        title: Text(
          stateName,
          style: TextStyle(
            color: context.col.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.col.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              'Guide Coming Soon',
              style: TextStyle(
                color: context.col.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'re working on the visitor guide\nfor $stateName. Check back soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.col.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _QuickFactsRow extends StatelessWidget {
  final List<_QuickFact> facts;
  const _QuickFactsRow({required this.facts});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: facts.map((f) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: context.col.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.col.border),
            ),
            child: Column(
              children: [
                Icon(f.icon, color: AppColors.primary, size: 18),
                const SizedBox(height: 6),
                Text(
                  f.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  f.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GuideCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _GuideCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.col.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.col.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: context.col.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color color;
  final IconData icon;

  const _BulletList({
    required this.items,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    color: context.col.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
