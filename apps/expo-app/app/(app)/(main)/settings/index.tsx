import { View } from 'react-native';
import { SettingsPagesList } from '../../../../components/settings/settings-pages-list';
import { CustomTabBar } from '../_layout';

export default function SettingsPage() {
  return (
    <View className="flex-1 bg-background">
      {/* Settings Content */}
      <View className="flex-1">
        <SettingsPagesList />
      </View>

      {/* Custom Tab Bar */}
      <CustomTabBar />
    </View>
  );
}
