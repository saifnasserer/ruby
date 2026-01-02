import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../core/theme/ruby_theme.dart';
import '../../core/models/task.dart';

class TaskBubble extends StatefulWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isToday;

  const TaskBubble({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
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

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(widget.task.audioPath!));
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
              onLongPress: widget.onLongPress,
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
                              ? RubyTheme.emerald.withOpacity(0.15)
                              : null,
                          borderRadius: BorderRadius.circular(
                            RubyTheme.radiusLarge(context),
                          ),
                          boxShadow: RubyTheme.softShadow,
                          border: widget.task.isCompleted
                              ? Border.all(
                                  color: RubyTheme.emerald.withOpacity(0.3),
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
                                  if (!widget.task.isCompleted &&
                                      widget.task.priority !=
                                          TaskPriority.normal)
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  if (!widget.task.isCompleted &&
                                      widget.task.priority !=
                                          TaskPriority.normal)
                                    SizedBox(
                                      width: RubyTheme.spacingS(context),
                                    ),

                                  // Completion indicator
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: widget.task.isCompleted
                                          ? RubyTheme.emerald
                                          : RubyTheme.pureWhite.withOpacity(
                                              0.2,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      widget.task.isCompleted
                                          ? Icons.check_rounded
                                          : Icons.circle_outlined,
                                      color: widget.task.isCompleted
                                          ? RubyTheme.pureWhite
                                          : RubyTheme.pureWhite.withOpacity(
                                              0.8,
                                            ),
                                      size: 16,
                                    ),
                                  ),

                                  SizedBox(width: RubyTheme.spacingS(context)),

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
                                                color: widget.task.isCompleted
                                                    ? RubyTheme.darkGray
                                                          .withOpacity(0.7)
                                                    : RubyTheme.pureWhite,
                                                decoration:
                                                    widget.task.isCompleted
                                                    ? TextDecoration.lineThrough
                                                    : null,
                                                fontWeight:
                                                    widget.task.isCompleted
                                                    ? FontWeight.w400
                                                    : FontWeight.w500,
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
                                                              ? RubyTheme
                                                                    .darkGray
                                                                    .withOpacity(
                                                                      0.5,
                                                                    )
                                                              : RubyTheme
                                                                    .pureWhite
                                                                    .withOpacity(
                                                                      0.7,
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
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.alarm_rounded,
                                                        size: 14,
                                                        color:
                                                            RubyTheme.pureWhite,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            RubyTheme.spacingXS(
                                                              context,
                                                            ) /
                                                            2,
                                                      ),
                                                      Text(
                                                        'موعد نهائي قادم',
                                                        style:
                                                            RubyTheme.caption(
                                                              context,
                                                            ).copyWith(
                                                              color: RubyTheme
                                                                  .pureWhite,
                                                              fontSize: 11,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                              ],
                                            ),
                                          ),

                                        // Category and tags
                                        if (widget.task.category != null ||
                                            widget.task.tags.isNotEmpty)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              top:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                            ),
                                            child: Wrap(
                                              spacing: RubyTheme.spacingXS(
                                                context,
                                              ),
                                              runSpacing:
                                                  RubyTheme.spacingXS(context) /
                                                  2,
                                              children: [
                                                if (widget.task.category !=
                                                    null)
                                                  _buildCategoryChip(),
                                                ...widget.task.tags.map(
                                                  (tag) => _buildTagChip(tag),
                                                ),
                                              ],
                                            ),
                                          ),
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
                              style: RubyTheme.caption(
                                context,
                              ).copyWith(color: RubyTheme.mediumGray),
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

  Widget _buildCategoryChip() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: RubyTheme.spacingS(context) / 2,
        vertical: RubyTheme.spacingXS(context) / 2,
      ),
      decoration: BoxDecoration(
        color: widget.task.isCompleted
            ? RubyTheme.mediumGray.withOpacity(0.2)
            : RubyTheme.pureWhite.withOpacity(0.2),
        borderRadius: BorderRadius.circular(RubyTheme.radiusSmall(context)),
      ),
      child: Text(
        widget.task.category!,
        style: RubyTheme.caption(context).copyWith(
          color: widget.task.isCompleted
              ? RubyTheme.darkGray.withOpacity(0.6)
              : RubyTheme.pureWhite.withOpacity(0.9),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: RubyTheme.spacingS(context) / 2,
        vertical: RubyTheme.spacingXS(context) / 2,
      ),
      decoration: BoxDecoration(
        color: widget.task.isCompleted
            ? RubyTheme.mediumGray.withOpacity(0.2)
            : RubyTheme.pureWhite.withOpacity(0.15),
        borderRadius: BorderRadius.circular(RubyTheme.radiusSmall(context)),
        border: Border.all(
          color: widget.task.isCompleted
              ? RubyTheme.mediumGray.withOpacity(0.3)
              : RubyTheme.pureWhite.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: RubyTheme.caption(context).copyWith(
          color: widget.task.isCompleted
              ? RubyTheme.darkGray.withOpacity(0.5)
              : RubyTheme.pureWhite.withOpacity(0.8),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (taskDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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
          SizedBox(width: 4),
          // Waves visualization placeholder - using a styled slider for now
          // but formatted to look more like a voice message
          SizedBox(
            width: 120,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: RubyTheme.pureWhite,
                inactiveTrackColor: RubyTheme.pureWhite.withOpacity(0.3),
                thumbColor: RubyTheme.pureWhite,
                trackHeight: 3.0,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5.0),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 10.0),
              ),
              child: Slider(
                value: _position.inMilliseconds.toDouble(),
                max: _duration.inMilliseconds.toDouble() > 0
                    ? _duration.inMilliseconds.toDouble()
                    : 1.0,
                onChanged: (value) async {
                  final position = Duration(milliseconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
            ),
          ),
          if (_duration.inSeconds > 0)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 8.0),
              child: Text(
                '${_position.inMinutes}:${(_position.inSeconds % 60).toString().padLeft(2, '0')}',
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
