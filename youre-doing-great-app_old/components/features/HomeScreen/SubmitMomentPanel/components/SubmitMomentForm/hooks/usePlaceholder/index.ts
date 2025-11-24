import { useMemo } from "react";

const PLACEHOLDERS = [
  "Brushed your teeth without rushing",
  "Maybe you just folded your laundry and that was enough",
  "Sent a message you've been putting off",
  "Cooked something decent (or at least edible)",
  "Did some quick stretches before sitting back down",
  "Finally cleared off that one annoying surface",
  "Maybe you just made your bed and called it a win",
  "Organized a tiny corner of your life",
  "Went for a walk instead of scrolling again",
  "Closed a tab you've had open for 3 weeks",
  "Cleaned something that was quietly bothering you",
  "Got dressed even if you had nowhere to go",
  "Maybe you just replied to that one hard email",
  "Moved your body a little — and that's not nothing",
  "Followed through on something small but real",
  "Maybe you took the high road today",
  "Chose to rest instead of forcing productivity",
  "Finally unsubscribed from that thing",
  "Let something go without needing to fix it",
  "Maybe you just showed up and that matters",
  "Said no when you could've said yes and regretted it",
  "Handled a tiny crisis like an adult",
  "Started something instead of planning forever",
  "Looked at your budget without immediately crying",
  "Maybe you cleaned up without telling anyone",
  "Helped someone without needing credit for it",
  "Got through a long call without losing your mind",
  "Maybe you set a timer and did the thing",
  "Faced a task you've been hiding from",
  "Did your thing — and you know which one",
];

const getRandomPlaceholder = () => {
  return PLACEHOLDERS[Math.floor(Math.random() * PLACEHOLDERS.length)];
};

const usePlaceholder = () => {
  return useMemo(() => getRandomPlaceholder(), []);
};

export default usePlaceholder;
