import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/models/task.dart';
import '../../core/utils/date_formatter.dart';

class TaskBubble extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final bool isToday;

  const TaskBubble({
    super.key,
    required this.task,
    this.onTap,
    this.isToday = false,
  });

  @override
  State<TaskBubble> createState() => _TaskBubbleState();
}

class _TaskBubbleState extends State<TaskBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  // Audio Player State
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.5), // Start slightly below
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutQuart,
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // Only animate if the task is newly created (less than 3 seconds ago)
    final isNew =
        DateTime.now().difference(widget.task.createdAt).inSeconds < 3;
    if (isNew) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }

    _setupAudioPlayer();
    _initAudioSource();
  }

  Future<void> _initAudioSource() async {
    if (widget.task.audioPath != null) {
      try {
        await _audioPlayer.setVolume(1.0); // Set to 100% volume
        await _audioPlayer.setSource(DeviceFileSource(widget.task.audioPath!));
      } catch (e) {
        print('Error initializing audio source: $e');
      }
    }
  }

  void _setupAudioPlayer() {
    if (widget.task.audioPath == null) return;

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
  }

  Future<void> _toggleAudio() async {
    if (widget.task.audioPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // If duration is zero, it might mean source wasn't loaded correctly or init failed.
        // Try playing directly with source to force load.
        if (_duration == Duration.zero && _position == Duration.zero) {
          await _audioPlayer.play(DeviceFileSource(widget.task.audioPath!));
        } else {
          if (_audioPlayer.state == PlayerState.completed) {
            await _audioPlayer.seek(Duration.zero);
          }
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      print('Error toggling audio: $e');
      // Fallback: try forcing play with source
      try {
        await _audioPlayer.play(DeviceFileSource(widget.task.audioPath!));
      } catch (e2) {
        print('Fallback play failed: $e2');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: RubyTheme.spacingM(context),
                  vertical: RubyTheme.spacingXS(context),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // RTL alignment
                  children: [
                    // Task bubble
                    Flexible(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: RubyTheme.spacingM(context),
                          vertical: RubyTheme.spacingM(context) / 2,
                        ),
                        decoration: BoxDecoration(
                          gradient: widget.task.isCompleted
                              ? null
                              : _getPriorityGradient(),
                          color: widget.task.isCompleted
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? RubyTheme.emerald.withOpacity(0.25)
                                    : RubyTheme.emerald.withOpacity(0.15))
                              : null,
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusLarge(context),
                          ),
                          boxShadow: RubyTheme.softShadow(context),
                          border: widget.task.isCompleted
                              ? Border.all(
                                  color: RubyTheme.success(
                                    context,
                                  ).withOpacity(0.3),
                                  width: 1,
                                )
                              : _getPriorityBorder(),
                        ),
                        child: widget.task.audioPath != null
                            ? _buildAudioPlayer()
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Priority indicator bar (left edge)
                                  // if (!widget.task.isCompleted &&
                                  //     widget.task.priority !=
                                  //         TaskPriority.normal)
                                  //   Container(
                                  //     width: 4,
                                  //     height: 40,
                                  //     decoration: BoxDecoration(
                                  //       color: _getPriorityColor(),
                                  //       borderRadius: BorderRadius.circular(2),
                                  //     ),
                                  //   ),
                                  // if (!widget.task.isCompleted &&
                                  //     widget.task.priority !=
                                  //         TaskPriority.normal)
                                  //   SizedBox(
                                  //     width: RubyTheme.spacingS(context),
                                  //   ),

                                  // // Completion indicator
                                  // Container(
                                  //   padding: const EdgeInsets.all(2),
                                  //   decoration: BoxDecoration(
                                  //     color: widget.task.isCompleted
                                  //         ? RubyTheme.emerald
                                  //         : RubyTheme.pureWhite.withOpacity(
                                  //             0.2,
                                  //           ),
                                  //     shape: BoxShape.circle,
                                  //   ),
                                  //   child: Icon(
                                  //     widget.task.isCompleted
                                  //         ? Icons.check_rounded
                                  //         : Icons.circle_outlined,
                                  //     color: widget.task.isCompleted
                                  //         ? RubyTheme.pureWhite
                                  //         : RubyTheme.pureWhite.withOpacity(
                                  //             0.8,
                                  //           ),
                                  //     size: 16,
                                  //   ),
                                  // ),

                                  // SizedBox(width: RubyTheme.spacingS(context)),

                                  // Task text and metadata
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Task text
                                        Text(
                                          widget.task.text,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: RubyTheme.bodyLarge(context)
                                              .copyWith(
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    widget.task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                color: widget.task.isCompleted
                                                    ? RubyTheme.textSecondary(
                                                        context,
                                                      ).withOpacity(
                                                        Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.dark
                                                            ? 0.8
                                                            : 0.5,
                                                      )
                                                    : RubyTheme
                                                          .pureWhite, // White text for active tasks
                                              ),
                                        ),

                                        // Subtask and Deadline indicators
                                        if (widget.task.subtasks.isNotEmpty ||
                                            (widget.task.deadlineDate != null &&
                                                !widget.task.isCompleted))
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                            ),
                                            child: Row(
                                              children: [
                                                if (widget
                                                    .task
                                                    .subtasks
                                                    .isNotEmpty) ...[
                                                  Icon(
                                                    Icons.checklist_rounded,
                                                    size: 14,
                                                    color:
                                                        widget.task.isCompleted
                                                        ? RubyTheme.darkGray
                                                              .withOpacity(0.5)
                                                        : RubyTheme.pureWhite
                                                              .withOpacity(0.7),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        RubyTheme.spacingXS(
                                                          context,
                                                        ) /
                                                        2,
                                                  ),
                                                  Text(
                                                    '${widget.task.subtasks.where((s) => s.isCompleted).length}/${widget.task.subtasks.length}',
                                                    style:
                                                        RubyTheme.caption(
                                                          context,
                                                        ).copyWith(
                                                          color:
                                                              widget
                                                                  .task
                                                                  .isCompleted
                                                              ? RubyTheme.textSecondary(
                                                                  context,
                                                                )
                                                              : RubyTheme.textTertiary(
                                                                  context,
                                                                ),
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                  ),
                                                ],
                                                if (widget
                                                        .task
                                                        .subtasks
                                                        .isNotEmpty &&
                                                    widget.task.deadlineDate !=
                                                        null)
                                                  const Spacer(),
                                                if (widget.task.deadlineDate !=
                                                        null &&
                                                    !widget.task.isCompleted)
                                                  _buildDeadlineBadge(),
                                              ],
                                            ),
                                          ),

                                        // Category and tags
                                        // if (widget.task.category != null ||
                                        //     widget.task.tags.isNotEmpty)
                                        //   Padding(
                                        //     padding: EdgeInsets.only(
                                        //       top:
                                        //           RubyTheme.spacingXS(context) /
                                        //           2,
                                        //     ),
                                        //     child: Wrap(
                                        //       spacing: RubyTheme.spacingXS(
                                        //         context,
                                        //       ),
                                        //       runSpacing:
                                        //           RubyTheme.spacingXS(context) /
                                        //           2,
                                        //       children: [
                                        //         if (widget.task.category !=
                                        //             null)
                                        //           _buildCategoryChip(),
                                        //         ...widget.task.tags.map(
                                        //           (tag) => _buildTagChip(tag),
                                        //         ),
                                        //       ],
                                        //     ),
                                        //   ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(width: RubyTheme.spacingS(context)),
                    // Time stamp and migration indicator
                    if (widget.isToday)
                      Container(
                        margin: EdgeInsets.only(
                          left: RubyTheme.spacingS(context),
                          top: RubyTheme.spacingXS(context),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatTime(widget.task.createdAt),
                              style: RubyTheme.caption(context).copyWith(
                                color: RubyTheme.textSecondary(context),
                              ),
                            ),
                            if (widget.task.isMigrated)
                              Container(
                                margin: EdgeInsets.only(top: 2),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: RubyTheme.rubyRed.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'متأخر',
                                  style: RubyTheme.caption(context).copyWith(
                                    color: RubyTheme.rubyRed,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Widget _buildCategoryChip() {
  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: RubyTheme.spacingS(context) / 2,
  //       vertical: RubyTheme.spacingXS(context) / 2,
  //     ),
  //     decoration: BoxDecoration(
  //       color: widget.task.isCompleted
  //           ? RubyTheme.mediumGray.withOpacity(0.2)
  //           : RubyTheme.pureWhite.withOpacity(0.2),
  //       borderRadius: BorderRadius.circular(RubyTheme.radiusSmall(context)),
  //     ),
  //     child: Text(
  //       widget.task.category!,
  //       style: RubyTheme.caption(context).copyWith(
  //         color: widget.task.isCompleted
  //             ? RubyTheme.success(context).withOpacity(0.1)
  //             : RubyTheme.surface(context),
  //         fontSize: 10,
  //         fontWeight: FontWeight.w600,
  //       ),
  //     ),
  //   );
  // }

  // Widget _buildTagChip(String tag) {
  //   return Container(
  //     padding: EdgeInsets.symmetric(
  //       horizontal: RubyTheme.spacingS(context) / 2,
  //       vertical: RubyTheme.spacingXS(context) / 2,
  //     ),
  //     decoration: BoxDecoration(
  //       color: widget.task.isCompleted
  //           ? RubyTheme.mediumGray.withOpacity(0.2)
  //           : RubyTheme.pureWhite.withOpacity(0.15),
  //       borderRadius: BorderRadius.circular(RubyTheme.radiusSmall(context)),
  //       border: Border.all(
  //         color: widget.task.isCompleted
  //             ? RubyTheme.mediumGray.withOpacity(0.3)
  //             : RubyTheme.pureWhite.withOpacity(0.3),
  //         width: 0.5,
  //       ),
  //     ),
  //     child: Text(
  //       tag,
  //       style: RubyTheme.caption(context).copyWith(
  //         color: widget.task.isCompleted
  //             ? RubyTheme.darkGray.withOpacity(0.5)
  //             : RubyTheme.pureWhite.withOpacity(0.8),
  //         fontSize: 9,
  //         fontWeight: FontWeight.w500,
  //       ),
  //     ),
  //   );
  // }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (taskDate == today) {
      return DateFormatter.formatTime(dateTime);
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  Gradient _getPriorityGradient() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHighGradient;
      default:
        return RubyTheme.priorityLowGradient;
    }
  }

  Color _getPriorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.important:
        return RubyTheme.priorityHigh;
      default:
        return RubyTheme.priorityLow;
    }
  }

  Border? _getPriorityBorder() {
    if (widget.task.priority == TaskPriority.normal) return null;
    return Border.all(color: _getPriorityColor().withOpacity(0.3), width: 1);
  }

  Widget _buildDeadlineBadge() {
    if (widget.task.deadlineDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadline = DateTime(
      widget.task.deadlineDate!.year,
      widget.task.deadlineDate!.month,
      widget.task.deadlineDate!.day,
    );

    final daysRemaining = deadline.difference(today).inDays;

    // Determine urgency color and icon
    Color badgeColor;
    IconData icon;
    String text;

    if (daysRemaining < 0) {
      // Overdue
      badgeColor = RubyTheme.priorityHigh;
      icon = Icons.warning_rounded;
      text =
          'متأخر ${daysRemaining.abs()} ${daysRemaining.abs() == 1 ? 'يوم' : 'أيام'}';
    } else if (daysRemaining == 0) {
      // Due today
      badgeColor = RubyTheme.priorityHigh;
      icon = Icons.alarm_on_rounded;
      text = 'الديدلابن النهارده';
    } else if (daysRemaining == 1) {
      // Due tomorrow
      badgeColor = Color(0xFFFFA726); // Orange
      icon = Icons.alarm_rounded;
      text = 'الديدلابن بكرا';
    } else if (daysRemaining <= 3) {
      // 2-3 days
      badgeColor = Color(0xFFFFA726); // Orange
      icon = Icons.alarm_rounded;
      text = '$daysRemaining أيام';
    } else if (daysRemaining <= 7) {
      // 4-7 days
      badgeColor = Color(0xFFFFC107); // Amber
      icon = Icons.schedule_rounded;
      text = '$daysRemaining أيام';
    } else {
      // More than 7 days
      badgeColor = RubyTheme.emerald;
      icon = Icons.schedule_rounded;
      text = '$daysRemaining يوم';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: RubyTheme.spacingS(context) / 1.5,
        vertical: RubyTheme.spacingXS(context) / 2.5,
      ),
      decoration: BoxDecoration(
        color: widget.task.isCompleted
            ? RubyTheme.textSecondary(context).withOpacity(0.2)
            : badgeColor.withOpacity(0.25),
        borderRadius: BorderRadius.circular(RubyTheme.radiusSmall(context)),
        border: Border.all(
          color: widget.task.isCompleted
              ? RubyTheme.textSecondary(context).withOpacity(0.3)
              : badgeColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: widget.task.isCompleted
                ? RubyTheme.textSecondary(context).withOpacity(0.5)
                : RubyTheme.pureWhite,
          ),
          SizedBox(width: RubyTheme.spacingXS(context) / 2),
          Text(
            text,
            style: RubyTheme.caption(context).copyWith(
              color: widget.task.isCompleted
                  ? RubyTheme.textSecondary(context).withOpacity(0.5)
                  : RubyTheme.pureWhite,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(RubyTheme.radiusLarge(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: RubyTheme.pureWhite,
            ),
            onPressed: _toggleAudio,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            iconSize: 32,
          ),
          // IconButton(
          //   icon: Icon(
          //     Icons.edit_note_rounded,
          //     color: RubyTheme.pureWhite.withOpacity(0.8),
          //   ),
          //   onPressed: widget.onTap,
          //   padding: EdgeInsets.zero,
          //   constraints: BoxConstraints(),
          //   iconSize: 24,
          //   tooltip: 'تفريغ النص',
          // ),
          SizedBox(width: 8),
          // Waveform visualization
          SizedBox(
            width: 120,
            height: 32,
            child: Stack(
              children: [
                // Waveform
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TaskBubbleWaveformPainter(
                      progress: _duration.inMilliseconds > 0
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0,
                      activeColor: RubyTheme.pureWhite,
                      inactiveColor: RubyTheme.pureWhite.withOpacity(0.3),
                    ),
                  ),
                ),
                // Invisible slider for seeking
                Positioned.fill(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.transparent,
                        inactiveTrackColor: Colors.transparent,
                        thumbColor: Colors.transparent,
                        thumbShape: RoundSliderThumbShape(
                          enabledThumbRadius: 0,
                        ),
                        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                        trackHeight: 32.0,
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.toDouble(),
                        max: _duration.inMilliseconds.toDouble() > 0
                            ? _duration.inMilliseconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          setState(() {
                            _position = Duration(milliseconds: value.toInt());
                          });
                        },
                        onChangeEnd: (value) async {
                          final position = Duration(
                            milliseconds: value.toInt(),
                          );
                          try {
                            await _audioPlayer.seek(position);
                          } catch (e) {
                            print('Error seeking: $e');
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_duration.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 8.0),
              child: Text(
                _isPlaying
                    ? '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}'
                    : '${_duration.inMinutes}:${(_duration.inSeconds % 60).toString().padLeft(2, '0')}',
                style: RubyTheme.caption(context).copyWith(
                  color: RubyTheme.pureWhite,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for task bubble waveform visualization
class _TaskBubbleWaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _TaskBubbleWaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = 25; // Fewer bars for smaller bubble
    final barWidth = size.width / (barCount * 2 - 1);
    final centerY = size.height / 2;

    // Generate pseudo-random heights for waveform bars
    final heights = List.generate(barCount, (index) {
      final baseHeight = 0.3 + (index % 3) * 0.2 + (index % 5) * 0.15;
      return size.height * baseHeight.clamp(0.2, 0.9);
    });

    for (int i = 0; i < barCount; i++) {
      final x = i * barWidth * 2;
      final barProgress = i / barCount;
      final isActive = barProgress <= progress;

      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..strokeWidth = barWidth
        ..strokeCap = StrokeCap.round;

      final barHeight = heights[i];
      canvas.drawLine(
        Offset(x, centerY - barHeight / 2),
        Offset(x, centerY + barHeight / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TaskBubbleWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
