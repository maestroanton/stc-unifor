import 'package:flutter/material.dart';
import 'dart:async';

import '../../../services/activity_tracker.dart';

/// Widget que registra automaticamente a atividade do usuário
/// Envolva as telas principais para habilitar o rastreamento
class ActivityWrapper extends StatefulWidget {
  final Widget child;
  final bool trackActivity;

  const ActivityWrapper({
    super.key,
    required this.child,
    this.trackActivity = true,
  });

  @override
  State<ActivityWrapper> createState() => _ActivityWrapperState();
}

class _ActivityWrapperState extends State<ActivityWrapper>
    with WidgetsBindingObserver {
  final ActivityTracker _tracker = ActivityTracker();

  @override
  void initState() {
    super.initState();
    if (widget.trackActivity) {
      WidgetsBinding.instance.addObserver(this);
      _initializeTracking();
    }
  }

  @override
  void dispose() {
    if (widget.trackActivity) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }

  Future<void> _initializeTracking() async {
    await _tracker.initializeTracking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.trackActivity) return;

    switch (state) {
      case AppLifecycleState.resumed:
        // App voltou ao primeiro plano — registra atividade
        _tracker.recordActivity();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App foi para segundo plano — não registra atividade
        // O temporizador periódico detecta inatividade
        break;
      case AppLifecycleState.detached:
        // App está sendo encerrado
        _tracker.stopTracking();
        break;
      case AppLifecycleState.hidden:
        // App está oculto, mas em execução
        break;
    }
  }

  void _onUserInteraction() {
    if (widget.trackActivity) {
      _tracker.recordActivity();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.trackActivity) {
      return widget.child;
    }

    return GestureDetector(
      onTap: _onUserInteraction,
      onTapDown: (_) => _onUserInteraction(),
      onScaleStart: (_) => _onUserInteraction(),
      onScaleUpdate: (_) => _onUserInteraction(),
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _onUserInteraction();
          return false;
        },
        child: MouseRegion(
          onHover: (_) => _onUserInteraction(),
          onEnter: (_) => _onUserInteraction(),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget auxiliar para telas que precisam registrar atividade manualmente
class ActivityRecorder extends StatelessWidget {
  final Widget child;
  final VoidCallback? onActivity;

  const ActivityRecorder({
    super.key,
    required this.child,
    this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ActivityTracker().recordActivity();
        onActivity?.call();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Widget de informações que mostra o status da sessão
class SessionInfoWidget extends StatefulWidget {
  final bool showWarningIcon;

  const SessionInfoWidget({
    super.key,
    this.showWarningIcon = true,
  });

  @override
  State<SessionInfoWidget> createState() => _SessionInfoWidgetState();
}

class _SessionInfoWidgetState extends State<SessionInfoWidget> {
  final ActivityTracker _tracker = ActivityTracker();
  Map<String, dynamic>? _sessionInfo;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
    
    // Atualiza informações da sessão periodicamente
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        _loadSessionInfo();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadSessionInfo() async {
    final info = await _tracker.getSessionInfo();
    if (mounted) {
      setState(() {
        _sessionInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessionInfo == null || _sessionInfo!['active'] != true) {
      return const SizedBox.shrink();
    }

    final remainingMinutes = _sessionInfo!['remainingMinutes'] as int;
    final isNearTimeout = _sessionInfo!['isNearTimeout'] as bool;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNearTimeout ? Colors.orange.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
        border: Border.all(
          color: isNearTimeout ? Colors.orange : Colors.green,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNearTimeout ? Icons.warning : Icons.access_time,
            size: 16,
            color: isNearTimeout ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            isNearTimeout 
                ? 'Sessão expira em ${remainingMinutes}min'
                : '${(remainingMinutes / 60).toStringAsFixed(1)}h restantes',
            style: TextStyle(
              fontSize: 12,
              color: isNearTimeout ? Colors.orange[800] : Colors.green[800],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isNearTimeout && widget.showWarningIcon) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () async {
                await _tracker.extendSession();
                _loadSessionInfo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sessão estendida com sucesso'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(
                  Icons.refresh,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Botão que registra atividade ao ser pressionado
class ActivityButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const ActivityButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: style,
      onPressed: onPressed == null ? null : () {
        ActivityTracker().recordActivity();
        onPressed!();
      },
      child: child,
    );
  }
}

/// Botão de texto que registra atividade ao ser pressionado
class ActivityTextButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const ActivityTextButton({
    super.key,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: style,
      onPressed: onPressed == null ? null : () {
        ActivityTracker().recordActivity();
        onPressed!();
      },
      child: child,
    );
  }
}

