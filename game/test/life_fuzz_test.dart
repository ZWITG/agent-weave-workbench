import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/business_kinds.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/finance.dart';
import 'package:relivable/engine/kin.dart' show seasonClock;
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/love.dart' show partnerOf;
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/variants.dart';

void main() {
  seasonClock = () => DateTime(2026, 8, 1);
  final storylets = [
    for (final f in storyletFiles)
      ...(jsonDecode(File('assets/storylets/$f').readAsStringSync()) as List)
          .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
  ];
  final engine = GameEngine(storylets);
  // A random player across many whole lives (and rich adult lives with
  // businesses), checking that nothing impossible ever happens: stats out
  // of range, two partners, a job in prison, people sharing an id,
  // unfilled text, and so on.
  test('random play keeps every life consistent', () {
    final issues = <String, int>{};
    var years = 0;
    void issue(String s) => issues[s] = (issues[s] ?? 0) + 1;
    for (var seed = 1; seed <= 220; seed++) {
      final rng = Random(seed);
      final rich = seed <= 80;
      final l = engine.newLife(seed: seed);
      if (rich) {
        l.age = 20 + rng.nextInt(30);
        l.money = [3000, 80000, 2000000, 300000000, 3000000000][seed % 5];
      }
      var seen = 0;
      final knownDups = <String>{};
      var multi = false, jobInPrison = false, staleMarried = false;
      var where = 'start';
      void check() {
        for (final k in [...Stats.visible, ...Stats.hidden]) {
          if (l.stats[k] < 0 || l.stats[k] > 100) {
            issue('stat $k out of range after $where');
          }
        }
        if (l.money.abs() > 1e14) issue('money overflow after $where');
        if (l.businesses.isNotEmpty &&
            (l.bizFocus < 0 || l.bizFocus >= l.businesses.length)) {
          issue('bizFocus out of range after $where');
        }
        final names = l.businesses.map((b) => b.name).toList();
        if (names.toSet().length != names.length) {
          issue('duplicate business names after $where');
        }
        if (l.savings < 0) issue('negative savings after $where');
        if (l.invested < 0) issue('negative invested after $where');
        if (l.fame < 0 || l.fame > 100) issue('fame out of range after $where');
        if (l.image < -100 || l.image > 100) {
          issue('image out of range after $where');
        }
        if (l.energy < 0) issue('negative energy after $where');
        if (l.followers.values.any((v) => v < 0)) {
          issue('negative followers after $where');
        }
        if (l.job != null && l.age < 13) issue('job under 13 after $where');
        if (l.job == null && l.salary > 0) {
          issue('salary without job after $where');
        }
        if (l.job != null && l.prison != null && !jobInPrison) {
          issue('NEW job while in prison after $where');
        }
        jobInPrison = l.job != null && l.prison != null;
        if (l.retired && l.job != null) issue('retired with job after $where');
        final partners = l.npcs
            .where((n) => n.alive && n.circle == 'Partner')
            .length;
        if (partners > 1 && !multi) {
          issue(
            'NEW two partners after $where: ${l.npcs.where((n) => n.alive && n.circle == 'Partner').map((n) => '${n.id}/${n.role}').join(' + ')}',
          );
        }
        multi = partners > 1;
        if (l.npcs.where((n) => n.alive && n.circle == 'Lover').length > 1) {
          issue('more than one lover after $where');
        }
        final stale =
            partnerOf(l) == null &&
            l.flags.containsKey('married') &&
            !l.flags.containsKey('widowed') &&
            !l.flags.containsKey('divorced');
        if (stale && !staleMarried) {
          final gone = l.npcs
              .where(
                (n) =>
                    n.role == 'Wife' ||
                    n.role == 'Husband' ||
                    n.circle == 'Exes',
              )
              .map((n) => '${n.circle}/${n.role}/${n.alive ? 'alive' : 'dead'}')
              .join(', ');
          issue('NEW married flag with no partner after $where [$gone]');
        }
        staleMarried = stale;
        if (l.npcs.any((n) => n.birthYear > l.year)) {
          issue('npc not born yet after $where');
        }
        final npcIds = l.npcs.map((n) => n.id).toList();
        final dups = <String>{};
        final seenIds = <String>{};
        for (final id in npcIds) {
          if (!seenIds.add(id)) dups.add(id);
        }
        for (final d in dups.difference(knownDups)) {
          final who = l.npcs
              .where((n) => n.id == d)
              .map((n) => '${n.circle}/${n.role}')
              .join(' + ');
          issue(
            'NEW duplicate npc id ${d.replaceAll(RegExp(r'[0-9]'), '#')} ($who) after $where',
          );
        }
        knownDups
          ..clear()
          ..addAll(dups);
        for (final n in l.npcs) {
          if (n.bond < 0 || n.bond > 100) {
            issue('npc bond out of range after $where');
          }
        }
        for (final e in l.debts.entries) {
          if (e.value < 0) issue('negative debt ${e.key} after $where');
        }
        final ids = l.assets.map((a) => a.id).toList();
        if (ids.toSet().length != ids.length) {
          issue('duplicate asset ids after $where');
        }
        if (l.sceneQueue.length > 15) {
          issue('scene queue piling up (${l.sceneQueue.length}) after $where');
        }
        for (final f in l.feed.skip(seen)) {
          final t = f.text;
          if (RegExp(r'null|NaN|Infinity|Instance of|\{|\}|@[a-z]|\$-|\$−|  ')
              .hasMatch(t)) {
            issue(
              'odd text after $where: ${t.length > 140 ? t.substring(0, 140) : t}',
            );
          }
        }
        seen = l.feed.length;
        for (final a in l.assets) {
          if (a.value < 0) issue('negative asset value ${a.kind} after $where');
        }
        for (final b in l.businesses) {
          for (final v in [b.quality, b.brand, b.satisfaction, b.morale]) {
            if (v < 0 || v > 100) {
              issue('business meter out of range after $where');
            }
          }
          if (b.staff < 1) issue('business with no staff after $where');
        }
      }

      try {
        for (var y = 0; y < (rich ? 45 : 110) && l.alive; y++) {
          years++;
          where = 'ageUp';
          var ev = engine.ageUp(l);
          check();
          var guard = 0;
          while (ev != null && guard++ < 20) {
            final open = ev.choices
                .where((c) => c.lockReason(l) == null)
                .toList();
            if (open.isEmpty) {
              issue('scene with no open choice: ${ev.id}');
              break;
            }
            where = 'choice in ${ev.id}';
            final c = open[rng.nextInt(open.length)];
            final m0 = l.money;
            engine.choose(l, ev, c);
            if (m0 >= 0 && l.money < 0 && c.needsMoney > 0) {
              issue('choice made money negative: ${ev.id} / ${c.label}');
            }
            check();
            ev = engine.nextScene(l);
          }
          if (!l.alive || l.prison != null) continue;
          for (var k = 0; k < 6; k++) {
            final open = engine.actions
                .where((a) => a.id != 'murder' && a.lockReason(l) == null)
                .toList();
            if (open.isEmpty) break;
            final a = open[rng.nextInt(open.length)];
            final vs = variantsFor(a.id)
                .where((v) => v.lockReason(l) == null)
                .toList();
            final v = vs.isEmpty ? null : vs[rng.nextInt(vs.length)];
            where = 'action ${a.id}${v == null ? '' : '/${v.id}'}';
            final m0 = l.money;
            engine.runAction(l, a, variant: v, score: rng.nextDouble());
            if (m0 >= 0 && l.money < -50000 && a.lockReason(l) == null) {
              issue(
                'action made money very negative: ${a.id}${v == null ? '' : '/${v.id}'}',
              );
            }
            check();
            var ev2 = engine.nextScene(l);
            var g2 = 0;
            while (ev2 != null && g2++ < 10) {
              final open2 = ev2.choices
                  .where((c) => c.lockReason(l) == null)
                  .toList();
              if (open2.isEmpty) {
                issue('scene with no open choice: ${ev2.id}');
                break;
              }
              where = 'choice in ${ev2.id}';
              final c = open2[rng.nextInt(open2.length)];
              final m1 = l.money;
              engine.choose(l, ev2, c);
              if (m1 >= 0 && l.money < -50000) {
                issue('choice made money negative: ${ev2.id} / ${c.label}');
              }
              check();
              ev2 = engine.nextScene(l);
            }
          }
          for (var k = 0; k < 3 && l.npcs.isNotEmpty; k++) {
            final n = l.npcs[rng.nextInt(l.npcs.length)];
            final avail = interactions
                .where((i) => i.appliesTo(n) && i.lockReason(l, n) == null)
                .toList();
            if (avail.isEmpty) continue;
            final i = avail[rng.nextInt(avail.length)];
            where = 'interact ${i.id}';
            engine.interact(l, n, i);
            check();
            var ev3 = engine.nextScene(l);
            var g3 = 0;
            while (ev3 != null && g3++ < 10) {
              final o = ev3.choices
                  .where((c) => c.lockReason(l) == null)
                  .toList();
              if (o.isEmpty) {
                issue('scene with no open choice: ${ev3.id}');
                break;
              }
              where = 'choice in ${ev3.id}';
              engine.choose(l, ev3, o[rng.nextInt(o.length)]);
              check();
              ev3 = engine.nextScene(l);
            }
          }
          // Business management.
          for (var i = 0; i < l.businesses.length; i++) {
            focusBusiness(l, i);
            where = 'biz moves';
            for (final m in bizMoves) {
              if (rng.nextBool() && bizMoveLock(l, m) == null) {
                final m0 = l.money;
                runBizMove(l, m, rng);
                if (m0 >= 0 && l.money < 0) {
                  issue('biz move negative money ${m.id}');
                }
              }
            }
            final kind = kindOf(l.business!);
            for (final p in kind?.perks ?? const <BizPerk>[]) {
              if (rng.nextBool() && perkLock(l, p) == null) buyPerk(l, p);
            }
            if (signatureLock(l) == null) {
              final m0 = l.money;
              runSignature(l, rng);
              if (m0 >= 0 && l.money < 0) issue('signature negative money');
            }
            check();
          }
        }
        // Save round trip.
        where = 'save';
        final copy = Life.fromJson(jsonDecode(jsonEncode(l.toJson())));
        if (jsonEncode(copy.toJson()) != jsonEncode(l.toJson())) {
          issue('save round trip differs');
        }
      } catch (e, st) {
        issue(
          'EXCEPTION at $where: $e ${st.toString().split('\n').take(3).join(' | ')}',
        );
      }
    }
    expect(years, greaterThan(5000));
    expect(issues.entries.map((e) => '${e.value}x ${e.key}').toList(), isEmpty);
  });
}
