import React, { useState, useEffect, useRef, useCallback } from 'react';
import {
  SafeAreaView,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  Animated,
  ScrollView,
  StatusBar,
} from 'react-native';
import NetInfo from '@react-native-community/netinfo';

// ─────────────────────────────────────────────────────────
// Helper – map raw connection type to a human-readable label
// ─────────────────────────────────────────────────────────
function getTypeLabel(type) {
  switch (type) {
    case 'wifi':      return 'Wi-Fi';
    case 'cellular':  return 'Cellular / Mobile Data';
    case 'ethernet':  return 'Ethernet';
    case 'bluetooth': return 'Bluetooth';
    case 'vpn':       return 'VPN';
    case 'other':     return 'Other';
    case 'none':
    case 'unknown':
    default:          return 'No Connection';
  }
}

// ─────────────────────────────────────────────────────────
// Helper – emoji icon for connection type
// ─────────────────────────────────────────────────────────
function getTypeIcon(type, isConnected) {
  if (!isConnected) return '📵';
  switch (type) {
    case 'wifi':      return '📶';
    case 'cellular':  return '📡';
    case 'ethernet':  return '🔌';
    case 'bluetooth': return '🔵';
    case 'vpn':       return '🔒';
    default:          return '🌐';
  }
}

// ─────────────────────────────────────────────────────────
// Main App component
// ─────────────────────────────────────────────────────────
export default function App() {
  // ── State ──────────────────────────────────────────────
  const [netState, setNetState] = useState({
    isConnected: null,      // true | false | null (loading)
    type: 'unknown',        // wifi | cellular | ethernet | none | unknown …
    isInternetReachable: null, // true | false | null
    details: null,
  });
  const [lastUpdated, setLastUpdated] = useState(null);
  const [refreshing, setRefreshing] = useState(false);
  const [history, setHistory] = useState([]);

  // ── Animation ref for the status indicator pulse ───────
  const pulseAnim  = useRef(new Animated.Value(1)).current;
  // Monotonic counter for unique history keys
  const keyCounter = useRef(0);

  // ── Pulse animation (runs whenever connected state changes) ──
  useEffect(() => {
    const pulse = Animated.loop(
      Animated.sequence([
        Animated.timing(pulseAnim, { toValue: 1.12, duration: 900, useNativeDriver: true }),
        Animated.timing(pulseAnim, { toValue: 1,    duration: 900, useNativeDriver: true }),
      ])
    );
    pulse.start();
    return () => pulse.stop();
  }, [netState.isConnected]);

  // ── Update state helper ────────────────────────────────
  const applyState = useCallback((state) => {
    const snapshot = {
      isConnected: state.isConnected,
      type: state.type,
      isInternetReachable: state.isInternetReachable,
      details: state.details,
    };
    setNetState(snapshot);
    setLastUpdated(new Date());
    // Prepend a history entry (keep last 6).
    // Use an incrementing counter for the key so that two events firing in
    // the same millisecond never produce the same key (fixes duplicate-key warning).
    // Also skip adding a history row when the connected+type state hasn't changed
    // (prevents the initial fetch and the first listener callback from both logging
    // an identical entry).
    setHistory((prev) => {
      const last = prev[0];
      if (last && last.connected === state.isConnected && last.type === state.type) {
        return prev; // no visible change – don't add a duplicate row
      }
      keyCounter.current += 1;
      return [
        {
          id: `hist-${keyCounter.current}`,
          connected: state.isConnected,
          type: state.type,
          time: new Date(),
        },
        ...prev.slice(0, 5),
      ];
    });
  }, []);

  // ── Step 2: Read initial connectivity state on mount ───
  useEffect(() => {
    NetInfo.fetch().then(applyState);
  }, [applyState]);

  // ── Step 3: Subscribe to live connectivity changes ─────
  useEffect(() => {
    // Register event listener; unsubscribe on unmount to avoid memory leaks
    const unsubscribe = NetInfo.addEventListener(applyState);
    return () => unsubscribe();
  }, [applyState]);

  // ── Step 5: Manual Refresh button handler ─────────────
  const handleRefresh = async () => {
    setRefreshing(true);
    const state = await NetInfo.fetch();
    applyState(state);
    setRefreshing(false);
  };

  // ── Derived values ─────────────────────────────────────
  const isOnline     = netState.isConnected === true;
  const isLoading    = netState.isConnected === null;
  const indicatorColor = isLoading
    ? COLORS.neutral
    : isOnline
      ? COLORS.online
      : COLORS.offline;

  const statusText = isLoading
    ? 'Checking…'
    : isOnline
      ? 'Online'
      : 'Offline';

  const reachabilityText =
    netState.isInternetReachable === null  ? 'Checking…'
    : netState.isInternetReachable === true ? 'Internet Reachable ✓'
    : netState.isInternetReachable === false ? 'No Internet Reachability ✗'
    : 'Unknown';

  // Format time
  const formatTime = (date) =>
    date ? date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : '—';

  // ── Render ─────────────────────────────────────────────
  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={COLORS.bg} />

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        <View style={styles.inner}>

          {/* ── App Header ─────────────────────────── */}
          <View style={styles.header}>
            <Text style={styles.headerTitle}>🌐 Connectivity Status</Text>
            <Text style={styles.headerSub}>Live network monitoring</Text>
          </View>

          {/* ── Main Status Indicator ──────────────── */}
          <View style={styles.indicatorSection}>
            <Animated.View
              style={[
                styles.indicatorRing,
                { borderColor: indicatorColor, transform: [{ scale: pulseAnim }] },
              ]}
            >
              <View style={[styles.indicatorCircle, { backgroundColor: indicatorColor }]}>
                <Text style={styles.indicatorIcon}>
                  {getTypeIcon(netState.type, isOnline)}
                </Text>
              </View>
            </Animated.View>
            <Text style={[styles.statusLabel, { color: indicatorColor }]}>{statusText}</Text>
          </View>

          {/* ── Info Cards ────────────────────────── */}
          <View style={styles.cardsRow}>
            {/* Connection Type */}
            <View style={styles.infoCard}>
              <Text style={styles.infoCardLabel}>Connection Type</Text>
              <Text style={styles.infoCardValue}>{getTypeLabel(netState.type)}</Text>
            </View>
            {/* Internet Reachability */}
            <View style={[styles.infoCard,
              netState.isInternetReachable === true  && styles.infoCardGreen,
              netState.isInternetReachable === false && styles.infoCardRed,
            ]}>
              <Text style={styles.infoCardLabel}>Reachability</Text>
              <Text style={styles.infoCardValue}>{reachabilityText}</Text>
            </View>
          </View>

          {/* ── Extra Details (Wi-Fi SSID etc.) ─── */}
          {netState.details && isOnline && (
            <View style={styles.detailsCard}>
              <Text style={styles.detailsTitle}>Connection Details</Text>
              {netState.type === 'wifi' && netState.details.ssid ? (
                <Text style={styles.detailRow}>📶  SSID: {netState.details.ssid}</Text>
              ) : null}
              {netState.details.strength !== undefined && netState.details.strength !== null ? (
                <Text style={styles.detailRow}>📊  Signal Strength: {netState.details.strength}%</Text>
              ) : null}
              {netState.type === 'cellular' && netState.details.cellularGeneration ? (
                <Text style={styles.detailRow}>📡  Generation: {netState.details.cellularGeneration?.toUpperCase()}</Text>
              ) : null}
              {netState.details.isConnectionExpensive !== undefined ? (
                <Text style={styles.detailRow}>
                  💰  Metered: {netState.details.isConnectionExpensive ? 'Yes' : 'No'}
                </Text>
              ) : null}
            </View>
          )}

          {/* ── Last Updated ──────────────────────── */}
          <Text style={styles.lastUpdated}>Last updated: {formatTime(lastUpdated)}</Text>

          {/* ── Refresh Button ────────────────────── */}
          <TouchableOpacity
            style={[styles.refreshBtn, refreshing && styles.refreshBtnDisabled]}
            onPress={handleRefresh}
            disabled={refreshing}
            accessibilityRole="button"
            accessibilityLabel="Refresh connectivity status"
          >
            <Text style={styles.refreshBtnText}>
              {refreshing ? '⏳  Refreshing…' : '🔄  Refresh Status'}
            </Text>
          </TouchableOpacity>

          {/* ── Change History ───────────────────── */}
          {history.length > 0 && (
            <View style={styles.historySection}>
              <Text style={styles.historyTitle}>Change History</Text>
              {history.map((entry) => (
                <View key={entry.id} style={styles.historyRow}>
                  <View style={[styles.historyDot,
                    { backgroundColor: entry.connected ? COLORS.online : COLORS.offline }
                  ]} />
                  <Text style={styles.historyText}>
                    {entry.connected ? '🟢 Online' : '🔴 Offline'}
                    {'  ·  '}
                    {getTypeLabel(entry.type)}
                    {'  ·  '}
                    {formatTime(entry.time)}
                  </Text>
                </View>
              ))}
            </View>
          )}

        </View>
      </ScrollView>
    </SafeAreaView>
  );
}

// ─────────────────────────────────────────────────────────
// Design Tokens
// ─────────────────────────────────────────────────────────
const COLORS = {
  bg:        '#0d1117',
  surface:   '#161b22',
  card:      '#1c2330',
  border:    '#30363d',
  online:    '#2ecc71',
  offline:   '#e74c3c',
  neutral:   '#f39c12',
  text:      '#e6edf3',
  textMuted: '#8b949e',
  accent:    '#58a6ff',
  greenBg:   '#0d2818',
  redBg:     '#3d1a1a',
};

// ─────────────────────────────────────────────────────────
// StyleSheet
// ─────────────────────────────────────────────────────────
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: COLORS.bg,
  },
  scroll: {
    flexGrow: 1,
    paddingBottom: 40,
  },
  inner: {
    flex: 1,
    paddingHorizontal: 20,
  },

  // Header
  header: {
    paddingTop: 24,
    paddingBottom: 20,
    alignItems: 'center',
  },
  headerTitle: {
    color: COLORS.text,
    fontSize: 24,
    fontWeight: '800',
    letterSpacing: 0.5,
  },
  headerSub: {
    color: COLORS.textMuted,
    fontSize: 13,
    marginTop: 4,
    letterSpacing: 0.5,
    textTransform: 'uppercase',
  },

  // Status Indicator
  indicatorSection: {
    alignItems: 'center',
    paddingVertical: 28,
  },
  indicatorRing: {
    width: 130,
    height: 130,
    borderRadius: 65,
    borderWidth: 3,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 18,
  },
  indicatorCircle: {
    width: 110,
    height: 110,
    borderRadius: 55,
    alignItems: 'center',
    justifyContent: 'center',
  },
  indicatorIcon: {
    fontSize: 42,
  },
  statusLabel: {
    fontSize: 28,
    fontWeight: '800',
    letterSpacing: 1,
  },

  // Info Cards
  cardsRow: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 14,
  },
  infoCard: {
    flex: 1,
    backgroundColor: COLORS.card,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  infoCardGreen: {
    borderColor: COLORS.online,
    backgroundColor: COLORS.greenBg,
  },
  infoCardRed: {
    borderColor: COLORS.offline,
    backgroundColor: COLORS.redBg,
  },
  infoCardLabel: {
    color: COLORS.textMuted,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: 6,
  },
  infoCardValue: {
    color: COLORS.text,
    fontSize: 14,
    fontWeight: '600',
  },

  // Details Card
  detailsCard: {
    backgroundColor: COLORS.card,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
    marginBottom: 14,
  },
  detailsTitle: {
    color: COLORS.textMuted,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: 10,
  },
  detailRow: {
    color: COLORS.text,
    fontSize: 13,
    paddingVertical: 4,
  },

  // Last Updated
  lastUpdated: {
    color: COLORS.textMuted,
    fontSize: 12,
    textAlign: 'center',
    marginBottom: 20,
  },

  // Refresh Button
  refreshBtn: {
    backgroundColor: COLORS.accent,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 28,
    elevation: 3,
    shadowColor: COLORS.accent,
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.35,
    shadowRadius: 6,
  },
  refreshBtnDisabled: {
    opacity: 0.6,
  },
  refreshBtnText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '700',
    letterSpacing: 0.5,
  },

  // History
  historySection: {
    backgroundColor: COLORS.card,
    borderRadius: 14,
    padding: 16,
    borderWidth: 1,
    borderColor: COLORS.border,
  },
  historyTitle: {
    color: COLORS.textMuted,
    fontSize: 11,
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: 12,
  },
  historyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 6,
    borderBottomWidth: 1,
    borderBottomColor: COLORS.border,
  },
  historyDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 10,
  },
  historyText: {
    color: COLORS.text,
    fontSize: 12,
    flex: 1,
  },
});
