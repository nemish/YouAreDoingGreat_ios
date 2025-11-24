import { RawThemedText } from "@/components/RawThemedText";

const QUICK_REACTIONS = [
  "Nice. Want to say what it was?",
  "That sounds good. Care to share more?",
  "I love that. What did you do?",
  "You did something. What kind?",
  "That feels like a win. Got details?",
  "That's a step. What was it?",
  "That sounds like progress. Tell me?",
  "That's great. What happened?",
  "I see some effort there. What did it look like?",
  "You showed up. What for?",
  "I'm curious. What was the action?",
  "Want to share what it was?",
  "Happy to hear that. Any details?",
  "That's a little spark. What lit it?",
  "That moment counts. What was it?",
  "You moved forward. In what way?",
  "That's a shift. What kind of one?",
  "You did a thing. Want to tell me what it was?",
  "Small wins are real. What was yours?",
  "That's enough to notice. What happened?",
];

const reaction =
  QUICK_REACTIONS[Math.floor(Math.random() * QUICK_REACTIONS.length)];

const QuickReaction = () => {
  return (
    <RawThemedText
      className="text-5xl font-bold opacity-60"
      fontFamily="PatrickHand"
    >
      {reaction}
    </RawThemedText>
  );
};

export default QuickReaction;
