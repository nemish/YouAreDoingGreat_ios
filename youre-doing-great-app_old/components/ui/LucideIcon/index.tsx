import {
  AlertTriangle,
  BookOpen,
  ChevronUp,
  ChevronsUp,
  CloudSun,
  Heart,
  HeartMinus,
  House,
  LayoutDashboard,
  Moon,
  Pencil,
  Route,
  Settings,
  SunMedium,
  Sunrise,
  Sunset,
  Telescope,
  Trash2,
  type LucideIcon as LucideIconType,
} from "lucide-react-native";

type IconName =
  | "alert-triangle"
  | "sunrise"
  | "cloud-sun"
  | "sun-medium"
  | "sunset"
  | "moon"
  | "heart"
  | "heart-minus"
  | "trash-2"
  | "house"
  | "telescope"
  | "pencil"
  | "layout-dashboard"
  | "book-open"
  | "settings"
  | "chevron-up"
  | "chevrons-up"
  | "route";

type Props = {
  name: IconName;
  size?: number;
  color?: string;
};

const iconMap: Record<IconName, LucideIconType> = {
  "alert-triangle": AlertTriangle,
  sunrise: Sunrise,
  "cloud-sun": CloudSun,
  "sun-medium": SunMedium,
  sunset: Sunset,
  moon: Moon,
  heart: Heart,
  "heart-minus": HeartMinus,
  "trash-2": Trash2,
  house: House,
  telescope: Telescope,
  pencil: Pencil,
  "layout-dashboard": LayoutDashboard,
  "book-open": BookOpen,
  settings: Settings,
  "chevron-up": ChevronUp,
  "chevrons-up": ChevronsUp,
  route: Route,
};

const LucideIcon = ({ name, size = 24, color = "white" }: Props) => {
  const Icon = iconMap[name];

  if (!Icon) {
    console.warn(`Icon "${name}" not found in iconMap`);
    return null;
  }

  return <Icon size={size} color={color} />;
};

export default LucideIcon;
