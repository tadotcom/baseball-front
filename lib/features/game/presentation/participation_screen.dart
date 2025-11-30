import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/models/game.dart';
import '../application/participation_provider.dart';
// TODO: Import AppTheme

class ParticipationScreen extends ConsumerStatefulWidget {
  final String gameId;
  final int gameCapacity;
  final int participantCount;
  final String placeName;
  final DateTime gameDateTime;

  const ParticipationScreen({
    super.key,
    required this.gameId,
    required this.gameCapacity,
    required this.participantCount,
    required this.placeName,
    required this.gameDateTime,
  });


  @override
  ConsumerState<ParticipationScreen> createState() => _ParticipationScreenState();
}

class _ParticipationScreenState extends ConsumerState<ParticipationScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTeam;
  String? _selectedPosition;
  final List<String> _teamOptions = ['チームA', 'チームB'];
  final List<String> _positionOptions = [
    '投手', '捕手', '一塁手', '二塁手', '三塁手', '遊撃手',
    '左翼手', '中堅手', '右翼手'
  ];

  Future<void> _submitParticipation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref.read(participationActionProvider.notifier).register(
        gameId: widget.gameId,
        teamDivision: _selectedTeam!,
        position: _selectedPosition!,
      );

      if (mounted) {
        print("[ParticipationScreen] Participation successful for game ${widget.gameId}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('「${widget.placeName}」への参加登録が完了しました。'),
              backgroundColor: Colors.green
          ),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      print("[ParticipationScreen] Participation error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().split(': ').last),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final participationState = ref.watch(participationActionProvider);
    final isLoading = participationState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text('参加登録')), //
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'チームとポジションを選択', //
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600), // H3?
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.placeName, style: Theme.of(context).textTheme.titleMedium),
                      SizedBox(height: 4),
                      Text('📅 ${DateFormat('yyyy/MM/dd HH:mm').format(widget.gameDateTime.toLocal())}', style: Theme.of(context).textTheme.bodySmall),
                      SizedBox(height: 4),
                      Text('募集: ${widget.participantCount} / ${widget.gameCapacity} 人', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              DropdownButtonFormField<String>(
                value: _selectedTeam,
                decoration: InputDecoration(
                  labelText: 'チーム区分 *',
                  prefixIcon: Icon(Icons.group_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), // Consistent styling
                ),
                items: _teamOptions.map((String team) {
                  return DropdownMenuItem<String>(
                    value: team,
                    child: Text(team),
                  );
                }).toList(),
                onChanged: isLoading ? null : (String? newValue) { // ★ 6. isLoadingで制御
                  setState(() {
                    _selectedTeam = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'チームを選択してください'; //
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedPosition,
                decoration: InputDecoration(
                  labelText: '守備ポジション *',
                  prefixIcon: Icon(Icons.sports_baseball_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: _positionOptions.map((String position) {
                  return DropdownMenuItem<String>(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: isLoading ? null : (String? newValue) { // ★ 7. isLoadingで制御
                  setState(() {
                    _selectedPosition = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'ポジションを選択してください'; //
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : _submitParticipation, // ★ 8. isLoadingで制御
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading // ★ 9. isLoadingで制御
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                    : const Text('登録する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}