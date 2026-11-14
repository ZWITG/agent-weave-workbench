import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/dynasty.dart' show heirsOf, heirLife;
import 'package:relivable/engine/echelon.dart';
import 'package:relivable/engine/elite.dart' show upperEchelon;
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/justice.dart' show crimeById, enterPrison;
import 'package:relivable/engine/kin.dart' show seasonClock;
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/variants.dart';

// Release check: random play through whole dynasties (a life, then its heir,
// then theirs), including whole prison sentences played from the inside
// and lives at the very top, checking the newer systems' rules as well as
// the basics: no exceptions, no stuck scenes, no broken text, prison and
// echelon values in range, and saves that load back the same.
void main() {
  seasonClock = () => DateTime(2026, 8, 1);
  final storylets = [
    for (final f in storyletFiles)
      ...(jsonDecode(File('assets/storylets/$f').readAsStringSync()) as List)
          .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
  ];
  final engine = GameEngine(storylets);

  test('release fuzz: dynasties, prison from inside and the top', () {
    final issues = <String, int>{};
    void issue(String s) => issues[s] = (issues[s] ?? 0) + 1;
    var years = 0, prisonYears = 0, eliteYears = 0, heirs = 0;

    for (var seed = 5001; seed <= 5090; seed++) {
      final rng = Random(seed);
      var l = engine.newLife(seed: seed);
      final mode = seed % 3; // 0 ordinary, 1 sent to prison, 2 very rich
      if (mode == 2) {
        l.age = 30;
        l.money = [150000000, 2000000000, 15000000000][seed % 3];
      }
      var where = 'start';
      var seen = 0;

      void check() {
        for (final k in [...Stats.visible, ...Stats.hidden]) {
          if (l.stats[k] < 0 || l.stats[k] > 100) {
            issue('stat $k range @$where');
          }
        }
        final p = l.prison;
        if (p != null) {
          if (p.stash < 0) issue('negative stash @$where');
          if (p.served < 0 || p.years < 0) issue('bad sentence @$where');
          if (p.items.toSet().length != p.items.length) {
            issue('duplicate cell items @$where');
          }
          for (final v in [p.behaviour, p.respect, p.gangStanding]) {
            if (v < 0 || v > 100) issue('prison meter range @$where');
          }
          if (p.solitary < 0) issue('negative solitary @$where');
        }
        if (upperEchelon(l)) {
          final inf = influence(l);
          if (inf < 0 || inf > 100) issue('influence range @$where');
          if (l.echelon['rivals'] != null && rivals(l).length != 8) {
            issue('rival count @$where');
          }
          for (final r in rivals(l)) {
            if ((r['worth'] as int) <= 0) issue('rival worth <= 0 @$where');
            final f = r['feud'] as int;
            if (f < 0 || f > 100) issue('feud range @$where');
          }
        }
        if (l.sceneQueue.length > 15) issue('scene queue piling up @$where');
        for (final f in l.feed.skip(seen)) {
          if (RegExp(r'null|NaN|Infinity|Instance of|\{|\}|\$-|\$−')
              .hasMatch(f.text)) {
            issue(
              'odd text @$where: ${f.text.length > 120 ? f.text.substring(0, 120) : f.text}',
            );
          }
        }
        seen = l.feed.length;
      }

      void scenes() {
        var ev = engine.nextScene(l);
        var g = 0;
        while (ev != null && g++ < 15) {
          final open = ev.choices
              .where((c) => c.lockReason(l) == null)
              .toList();
          if (open.isEmpty) {
            issue('scene with no open choice: ${ev.id}');
            break;
          }
          where = 'choice ${ev.id}';
          engine.choose(l, ev, open[rng.nextInt(open.length)]);
          check();
          ev = engine.nextScene(l);
        }
        if (g >= 15) issue('scene loop: ${l.sceneQueue.take(3)}');
      }

      try {
        for (var gen = 0; gen < 3; gen++) {
          var sent = false;
          for (var y = 0; y < 95 && l.alive; y++) {
            years++;
            if (l.prison != null) prisonYears++;
            if (upperEchelon(l)) eliteYears++;
            // Ordinary lives get a sentence in their thirties.
            if (mode == 1 && !sent && l.age >= 30 && l.prison == null) {
              sent = true;
              enterPrison(l, crimeById('burglary'), 3 + seed % 5);
            }
            where = 'ageUp';
            final ev = engine.ageUp(l);
            check();
            if (ev != null) {
              final open = ev.choices
                  .where((c) => c.lockReason(l) == null)
                  .toList();
              if (open.isEmpty) {
                issue('scene with no open choice: ${ev.id}');
              } else {
                where = 'choice ${ev.id}';
                engine.choose(l, ev, open[rng.nextInt(open.length)]);
                check();
              }
            }
            scenes();
            if (!l.alive) break;
            // Activities, in prison too (only what is open there).
            for (var k = 0; k < 5; k++) {
              final open = engine.actions
                  .where((a) => a.id != 'murder' && a.lockReason(l) == null)
                  .toList();
              if (open.isEmpty) break;
              final a = open[rng.nextInt(open.length)];
              if (l.prison != null &&
                  a.category != 'Prison' &&
                  !const {'read', 'meditate'}.contains(a.id)) {
                issue('outside action open in prison: ${a.id}');
              }
              final vs = variantsFor(a.id)
                  .where((v) => v.lockReason(l) == null)
                  .toList();
              final v = vs.isEmpty ? null : vs[rng.nextInt(vs.length)];
              where = 'action ${a.id}${v == null ? '' : '/${v.id}'}';
              engine.runAction(l, a, variant: v, score: rng.nextDouble());
              check();
              scenes();
              if (!l.alive) break;
            }
            if (!l.alive || l.prison != null) continue;
            for (var k = 0; k < 2 && l.npcs.isNotEmpty; k++) {
              final n = l.npcs[rng.nextInt(l.npcs.length)];
              final avail = interactions
                  .where((i) => i.appliesTo(n) && i.lockReason(l, n) == null)
                  .toList();
              if (avail.isEmpty) continue;
              where = 'interact';
              engine.interact(l, n, avail[rng.nextInt(avail.length)]);
              check();
              scenes();
            }
          }
          // Save round trip at the end of each life.
          where = 'save';
          final json = jsonEncode(l.toJson());
          final copy = Life.fromJson(jsonDecode(json));
          if (jsonEncode(copy.toJson()) != json) {
            issue('save round trip differs');
          }
          // Continue as an heir if there is one.
          final kids = heirsOf(l);
          if (l.alive || kids.isEmpty) break;
          where = 'heir';
          l = heirLife(l, kids[rng.nextInt(kids.length)]);
          seen = 0;
          heirs++;
          check();
        }
      } catch (e, st) {
        issue(
          'EXCEPTION at $where: $e ${st.toString().split('\n').take(4).join(' | ')}',
        );
      }
    }
    // ignore: avoid_print
    print(
      'years $years · prison years $prisonYears · elite years $eliteYears · heirs $heirs',
    );
    expect(prisonYears, greaterThan(50));
    expect(eliteYears, greaterThan(200));
    expect(issues.entries.map((e) => '${e.value}x ${e.key}').toList(), isEmpty);
  });
}
