import { StatusBar } from 'expo-status-bar';
import * as Updates from 'expo-updates';
import { Button, StyleSheet, Text, View } from 'react-native';

// scripts/publish-update.sh exports the broken update with EXPO_PUBLIC_CRASH_ON_LAUNCH=1.
// It throws while the bundle runs, before the first render. expo-updates error recovery then
// falls back to the embedded update and relaunches the app.
if (process.env.EXPO_PUBLIC_CRASH_ON_LAUNCH === '1') {
  throw new Error('Crash on launch on purpose');
}

// Changes on each JS start, so a reload shows a new value.
const startedAt = new Date().toISOString().slice(11, 23);

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>
        {Updates.isEmbeddedLaunch ? 'Embedded update' : 'Downloaded update'}
      </Text>
      <Text>updateId: {Updates.updateId ?? 'none'}</Text>
      <Text>JS started at {startedAt} (UTC)</Text>
      <Button title="Reload" onPress={() => Updates.reloadAsync()} />
      <StatusBar style="auto" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
  },
});
