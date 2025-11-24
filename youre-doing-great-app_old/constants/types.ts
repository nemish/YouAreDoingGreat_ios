export type Moment = {
  id: string;
  text: string;
  submittedAt: string;
  happenedAt: string;
  tz?: string;
  isFavorite?: boolean;
  praise?: string;
  timeAgo?: number;
  tags?: string[];
  action?: string;
};

export type TimeOfDay = "sunrise" | "cloud-sun" | "sun-medium" | "sunset" | "moon";

export type DaySummary = {
  id: string;
  date: string;
  text: string | null;
  tags: string[];
  momentsCount: number;
  timesOfDay: TimeOfDay[];
  createdAt: string;
};

export type PaginatedTimelineResponse = {
  data: DaySummary[];
  nextCursor: string | null;
  hasNextPage: boolean;
};

export type UserFeedback = {
  id: string;
  title: string;
  text: string;
  createdAt: string;
};

export type CreateUserFeedbackRequest = {
  title: string;
  text: string;
};

export type CreateUserFeedbackResponse = {
  item: UserFeedback;
};
