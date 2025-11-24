# AI Agent Guidelines

## TypeScript Preferences

### Always Use `type` Instead of `interface`

**Prefer types for all type definitions:**

```typescript
// ✅ DO: Use type
type User = {
  id: string;
  name: string;
  email: string;
};

type ApiResponse<T> = {
  data: T;
  status: "success" | "error";
  message?: string;
};

// ❌ DON'T: Use interface
interface User {
  id: string;
  name: string;
  email: string;
}
```

**Reasons:**

- Better consistency across the codebase
- More flexible with union types, intersections, and mapped types
- No confusing declaration merging
- Explicit and clear intent

### Type Extensions

Use intersection types instead of interface extends:

```typescript
// ✅ DO: Use intersection types
type Animal = {
  name: string;
};

type Dog = Animal & {
  breed: string;
};

// ❌ DON'T: Use interface extends
interface Dog extends Animal {
  breed: string;
}
```

### Union Types

Always use types for unions:

```typescript
// ✅ DO: Use type for unions
type Status = "loading" | "success" | "error";
type ID = string | number;

// ❌ DON'T: Try to use interface for unions
```

### Explicit Type Definitions

**Always prefer explicit type definitions over inline types in function parameters:**

```typescript
// ✅ DO: Use explicit type definitions
type Props = {
  item: Moment;
  index: number;
};

const MomentItem = React.memo(({ item, index }: Props) => {
  return <View>...</View>;
});

// ✅ DO: Use explicit types for callback parameters
type RenderItemProps = {
  item: { id: string; moments: Moment[] };
  index: number;
};

const renderMoment = useCallback(({ item, index }: RenderItemProps) => {
  return <View>...</View>;
}, []);

// ❌ DON'T: Use inline type definitions
const MomentItem = React.memo(
  ({ item, index }: { item: Moment; index: number }) => {
    return <View>...</View>;
  }
);

// ❌ DON'T: Use inline types in callbacks
const renderMoment = useCallback(
  ({
    item,
    index,
  }: {
    item: { id: string; moments: Moment[] };
    index: number;
  }) => {
    return <View>...</View>;
  },
  []
);
```

**Reasons:**

- Better readability and maintainability
- Easier to reuse types across multiple functions
- Clearer separation of concerns
- Consistent with the codebase style
- Easier to refactor and update types

## API Integration Guidelines

### API Type Definitions

**Define comprehensive types for all API responses and requests:**

```typescript
// ✅ DO: Define complete API types
type User = {
  id: string;
  userId: string;
  status: "newcomer" | "paywall_needed" | "premium";
};

type Moment = {
  id: string;
  text: string;
  submittedAt: string; // ISO date-time
  tz: string;
  action: string;
  praise: string;
  isFavorite: boolean;
  archivedAt: string | null; // ISO date-time
};

type CreateMomentRequest = {
  text: string; // 1-1000 characters
  submittedAt?: string; // ISO date-time, optional
  tz?: string; // optional
};

type UpdateMomentRequest = {
  isFavorite: boolean;
};

type PaginatedMomentsResponse = {
  data: Moment[];
  nextCursor: string | null; // ISO date-time
  hasNextPage: boolean;
};

type ErrorResponse = {
  error: string;
  message?: string;
};

// ❌ DON'T: Use any or incomplete types
type ApiResponse = any;
type Moment = { id: string; text: string }; // Missing fields
```

### Authentication Headers

**Always include authentication headers in API requests:**

```typescript
// ✅ DO: Use consistent authentication headers
const apiClient = {
  get: (url: string) =>
    fetch(`${baseUrl}${url}`, {
      headers: {
        "x-user-id": getCurrentUserId(),
        "Content-Type": "application/json",
      },
    }),

  post: (url: string, data: any) =>
    fetch(`${baseUrl}${url}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-user-id": getCurrentUserId(),
      },
      body: JSON.stringify(data),
    }),
};

// ✅ DO: Create a reusable hook for authentication
const useAuthHeaders = () => {
  const userId = useCurrentUserId();

  return useMemo(
    () => ({
      "x-user-id": userId,
      "Content-Type": "application/json",
    }),
    [userId]
  );
};

// ❌ DON'T: Forget authentication headers
fetch("/api/v1/moments"); // Missing x-user-id header
```

### React Query Integration

**Use TanStack Query for all API data fetching:**

```typescript
// ✅ DO: Use useInfiniteQuery for paginated data
const useMoments = () => {
  const headers = useAuthHeaders();

  return useInfiniteQuery({
    queryKey: ["moments"],
    queryFn: ({ pageParam }) =>
      fetch(`/api/v1/moments?cursor=${pageParam || ""}&limit=20`, {
        headers,
      }).then((res) => {
        if (!res.ok) throw new Error("Failed to fetch moments");
        return res.json() as Promise<PaginatedMomentsResponse>;
      }),
    getNextPageParam: (lastPage) =>
      lastPage.hasNextPage ? lastPage.nextCursor : undefined,
    initialPageParam: undefined,
  });
};

// ✅ DO: Use useMutation for data mutations
const useCreateMoment = () => {
  const queryClient = useQueryClient();
  const headers = useAuthHeaders();

  return useMutation({
    mutationFn: (data: CreateMomentRequest) =>
      fetch("/api/v1/moments", {
        method: "POST",
        headers,
        body: JSON.stringify(data),
      }).then((res) => {
        if (!res.ok) throw new Error("Failed to create moment");
        return res.json();
      }),
    onSuccess: () => {
      // Invalidate and refetch moments
      queryClient.invalidateQueries({ queryKey: ["moments"] });
    },
  });
};

// ✅ DO: Use useQuery for single resource fetching
const useUserProfile = () => {
  const headers = useAuthHeaders();

  return useQuery({
    queryKey: ["user", "profile"],
    queryFn: () =>
      fetch("/api/v1/user/me", { headers }).then((res) => {
        if (!res.ok) throw new Error("Failed to fetch user profile");
        return res.json() as Promise<{ item: User }>;
      }),
  });
};

// ❌ DON'T: Use useState for API data
const [moments, setMoments] = useState<Moment[]>([]);
const [loading, setLoading] = useState(false);

useEffect(() => {
  setLoading(true);
  fetch("/api/v1/moments")
    .then((res) => res.json())
    .then((data) => setMoments(data.data))
    .finally(() => setLoading(false));
}, []);
```

### Error Handling

**Implement comprehensive error handling for API responses:**

```typescript
// ✅ DO: Handle specific API errors
const handleApiError = (error: any) => {
  if (error.status === 400) {
    if (error.error === "Daily limit reached") {
      showToast("You can only submit 5 moments per day");
    } else if (error.error === "Invalid cursor format") {
      showToast("Invalid pagination cursor");
    }
  } else if (error.status === 401) {
    // Redirect to login
    navigateToLogin();
  } else if (error.status === 403) {
    showToast("You do not have permission to perform this action");
  } else if (error.status === 404) {
    showToast("Resource not found");
  } else {
    showToast("An unexpected error occurred");
  }
};

// ✅ DO: Use error boundaries for API errors
const ApiErrorBoundary = ({ children }: { children: React.ReactNode }) => {
  return (
    <ErrorBoundary fallback={<ApiErrorFallback />} onError={handleApiError}>
      {children}
    </ErrorBoundary>
  );
};

// ❌ DON'T: Ignore API errors
fetch("/api/v1/moments").then((res) => res.json()); // No error handling
```

### Data Validation

**Validate API data on the client side:**

```typescript
// ✅ DO: Validate API responses
const validateMoment = (data: any): Moment => {
  if (!data.id || typeof data.id !== "string") {
    throw new Error("Invalid moment ID");
  }
  if (!data.text || typeof data.text !== "string" || data.text.length > 1000) {
    throw new Error("Invalid moment text");
  }
  if (!data.submittedAt || !isValidISODate(data.submittedAt)) {
    throw new Error("Invalid submittedAt date");
  }

  return data as Moment;
};

// ✅ DO: Validate request data before sending
const validateCreateMomentRequest = (data: CreateMomentRequest): void => {
  if (!data.text || data.text.trim().length === 0) {
    throw new Error("Text is required");
  }
  if (data.text.length > 1000) {
    throw new Error("Text must be 1000 characters or less");
  }
  if (data.submittedAt && !isValidISODate(data.submittedAt)) {
    throw new Error("Invalid submittedAt date format");
  }
};

// ❌ DON'T: Trust API data without validation
const moment = response.data; // No validation
```

### Optimistic Updates

**Implement optimistic updates for better UX:**

```typescript
// ✅ DO: Use optimistic updates for mutations
const useUpdateMomentFavorite = () => {
  const queryClient = useQueryClient();
  const headers = useAuthHeaders();

  return useMutation({
    mutationFn: ({ id, isFavorite }: { id: string; isFavorite: boolean }) =>
      fetch(`/api/v1/moments/${id}`, {
        method: "PUT",
        headers,
        body: JSON.stringify({ isFavorite }),
      }).then((res) => {
        if (!res.ok) throw new Error("Failed to update moment");
        return res.json();
      }),
    onMutate: async ({ id, isFavorite }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ["moments"] });

      // Snapshot previous value
      const previousMoments = queryClient.getQueryData(["moments"]);

      // Optimistically update
      queryClient.setQueryData(["moments"], (old: any) => ({
        ...old,
        pages: old.pages.map((page: any) => ({
          ...page,
          data: page.data.map((moment: Moment) =>
            moment.id === id ? { ...moment, isFavorite } : moment
          ),
        })),
      }));

      return { previousMoments };
    },
    onError: (err, variables, context) => {
      // Rollback on error
      if (context?.previousMoments) {
        queryClient.setQueryData(["moments"], context.previousMoments);
      }
    },
    onSettled: () => {
      // Always refetch after error or success
      queryClient.invalidateQueries({ queryKey: ["moments"] });
    },
  });
};

// ❌ DON'T: Wait for server response before updating UI
const handleFavorite = async (id: string) => {
  setLoading(true);
  await updateMoment(id, { isFavorite: true });
  setLoading(false);
  // UI only updates after server response
};
```

### Custom Hooks for API Operations

**Create reusable hooks for API operations:**

```typescript
// ✅ DO: Create custom hooks for API operations
const useMomentsApi = () => {
  const headers = useAuthHeaders();

  const getMoments = useCallback(
    async (cursor?: string, limit = 20) => {
      const url = `/api/v1/moments?limit=${limit}${
        cursor ? `&cursor=${cursor}` : ""
      }`;
      const response = await fetch(url, { headers });

      if (!response.ok) {
        throw new Error(`Failed to fetch moments: ${response.status}`);
      }

      return response.json() as Promise<PaginatedMomentsResponse>;
    },
    [headers]
  );

  const createMoment = useCallback(
    async (data: CreateMomentRequest) => {
      const response = await fetch("/api/v1/moments", {
        method: "POST",
        headers,
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Failed to create moment: ${response.status}`);
      }

      return response.json();
    },
    [headers]
  );

  const updateMoment = useCallback(
    async (id: string, data: UpdateMomentRequest) => {
      const response = await fetch(`/api/v1/moments/${id}`, {
        method: "PUT",
        headers,
        body: JSON.stringify(data),
      });

      if (!response.ok) {
        throw new Error(`Failed to update moment: ${response.status}`);
      }

      return response.json();
    },
    [headers]
  );

  const archiveMoment = useCallback(
    async (id: string) => {
      const response = await fetch(`/api/v1/moments/${id}`, {
        method: "DELETE",
        headers,
      });

      if (!response.ok) {
        throw new Error(`Failed to archive moment: ${response.status}`);
      }

      return response.json();
    },
    [headers]
  );

  return {
    getMoments,
    createMoment,
    updateMoment,
    archiveMoment,
  };
};

// ❌ DON'T: Duplicate API logic across components
const Component1 = () => {
  const fetchMoments = async () => {
    // Duplicated API logic
  };
};

const Component2 = () => {
  const fetchMoments = async () => {
    // Same duplicated API logic
  };
};
```

### Business Logic Validation

**Implement client-side business logic validation:**

```typescript
// ✅ DO: Validate business rules on client side
const useMomentValidation = () => {
  const { data: user } = useUserProfile();

  const canCreateMoment = useCallback(() => {
    if (!user?.item) return false;

    // Check user status
    if (user.item.status === "paywall_needed") {
      return false;
    }

    // Check daily limit (approximate, server is authoritative)
    const todayMoments = getTodayMomentsCount();
    return todayMoments < 5;
  }, [user]);

  const getDailyLimitRemaining = useCallback(() => {
    const todayMoments = getTodayMomentsCount();
    return Math.max(0, 5 - todayMoments);
  }, []);

  return {
    canCreateMoment,
    getDailyLimitRemaining,
    userStatus: user?.item?.status,
  };
};

// ✅ DO: Show appropriate UI based on business rules
const CreateMomentButton = () => {
  const { canCreateMoment, getDailyLimitRemaining, userStatus } =
    useMomentValidation();

  if (userStatus === "paywall_needed") {
    return <UpgradeButton />;
  }

  if (!canCreateMoment()) {
    return (
      <Text className="text-gray-500">
        Daily limit reached ({getDailyLimitRemaining()} remaining)
      </Text>
    );
  }

  return <CreateMomentForm />;
};

// ❌ DON'T: Ignore business rules on client side
const CreateMomentButton = () => {
  return <CreateMomentForm />; // No validation
};
```

## React Native Guidelines

### Animation Libraries

**Always use Moti or React Native Reanimated for animations:**

```typescript
// ✅ DO: Use Moti for declarative animations
import { MotiView, MotiPressable } from "moti";
import { MotiPressable } from "moti/interactions";

<MotiPressable
  animate={({ pressed }: { pressed: boolean }) => ({
    scale: pressed ? 0.95 : 1,
  })}
  transition={{
    type: "timing",
    duration: 150,
  }}
>
  <MotiView
    from={{ opacity: 0 }}
    animate={{ opacity: 1 }}
    transition={{ type: "timing" }}
  />
</MotiPressable>;

// ✅ DO: Use Reanimated for complex animations
import {
  useSharedValue,
  useAnimatedStyle,
  withTiming,
} from "react-native-reanimated";

const scale = useSharedValue(1);
const animatedStyle = useAnimatedStyle(() => ({
  transform: [{ scale: scale.value }],
}));

// ❌ DON'T: Use React Native's Animated API
import { Animated } from "react-native";
const scaleAnim = useRef(new Animated.Value(1)).current;
```

**Reasons:**

- Better performance with native driver
- More intuitive declarative API (Moti)
- Better TypeScript support
- Consistent with modern React Native development
- Smoother 60fps animations

### Component Structure

**Always use functional components with hooks:**

```typescript
// ✅ DO: Functional component with hooks
const MyComponent = ({ prop1, prop2 }: Props) => {
  const [state, setState] = useState(initialValue);

  useEffect(() => {
    // side effects
  }, []);

  return <View>...</View>;
};

// ❌ DON'T: Class components
class MyComponent extends React.Component {
  // ...
}
```

### Props and State

**Use explicit typing for all props and state:**

```typescript
// ✅ DO: Explicit prop types
type Props = {
  title: string;
  onPress: () => void;
  items: Item[];
  optional?: boolean;
};

// ✅ DO: Explicit state types
const [items, setItems] = useState<Item[]>([]);
const [loading, setLoading] = useState<boolean>(false);
```

### Performance Optimization

**Use React.memo for expensive components:**

```typescript
// ✅ DO: Memoize expensive components
const ExpensiveComponent = React.memo(({ data }: Props) => {
  return <View>...</View>;
});

// ✅ DO: Use useCallback for event handlers
const handlePress = useCallback(() => {
  // handler logic
}, [dependencies]);
```

## Form Handling Guidelines

### React Hook Form

**Always use react-hook-form for form handling:**

```typescript
// ✅ DO: Use react-hook-form for all forms
import { Controller, useForm } from "react-hook-form";

type ContactFormData = {
  title: string;
  message: string;
};

const ContactForm = () => {
  const {
    control,
    handleSubmit,
    formState: { isSubmitting, errors },
    reset,
  } = useForm<ContactFormData>({
    defaultValues: {
      title: "",
      message: "",
    },
  });

  const onSubmit = async (data: ContactFormData) => {
    try {
      await submitContactForm(data);
      reset();
      showSuccessMessage("Message sent successfully!");
    } catch (error) {
      showErrorMessage("Failed to send message");
    }
  };

  return (
    <View className="space-y-4">
      <Controller
        control={control}
        name="title"
        rules={{
          required: "Subject is required",
          minLength: {
            value: 3,
            message: "Subject must be at least 3 characters",
          },
        }}
        render={({ field: { onChange, onBlur, value } }) => (
          <View>
            <CommonText className="text-white font-medium mb-2">
              Subject
            </CommonText>
            <TextInput
              value={value}
              onChangeText={onChange}
              onBlur={onBlur}
              placeholder="What's this about?"
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              className="rounded-lg px-4 py-3 text-white border border-white/30"
            />
            {errors.title && (
              <CommonText className="text-red-400 text-sm mt-1">
                {errors.title.message}
              </CommonText>
            )}
          </View>
        )}
      />

      <Controller
        control={control}
        name="message"
        rules={{
          required: "Message is required",
          minLength: {
            value: 10,
            message: "Message must be at least 10 characters",
          },
          maxLength: {
            value: 1000,
            message: "Message must be less than 1000 characters",
          },
        }}
        render={({ field: { onChange, onBlur, value } }) => (
          <View>
            <CommonText className="text-white font-medium mb-2">
              Message
            </CommonText>
            <TextInput
              value={value}
              onChangeText={onChange}
              onBlur={onBlur}
              placeholder="Tell us what's on your mind..."
              placeholderTextColor="rgba(255, 255, 255, 0.5)"
              multiline
              numberOfLines={4}
              textAlignVertical="top"
              className="rounded-lg px-4 py-3 text-white border border-white/30 min-h-[100px]"
            />
            {errors.message && (
              <CommonText className="text-red-400 text-sm mt-1">
                {errors.message.message}
              </CommonText>
            )}
          </View>
        )}
      />

      <FancyButton
        text={isSubmitting ? "Sending..." : "Send Message"}
        onPress={handleSubmit(onSubmit)}
        size="base"
        kind="warmEvening"
        fullWidth
        disabled={isSubmitting}
      />
    </View>
  );
};

// ❌ DON'T: Use manual state management for forms
const BadContactForm = () => {
  const [title, setTitle] = useState("");
  const [message, setMessage] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  const handleSubmit = async () => {
    if (!title.trim() || !message.trim()) {
      // Manual validation
      return;
    }
    setIsSubmitting(true);
    try {
      await submitContactForm({ title, message });
      setTitle("");
      setMessage("");
    } catch (error) {
      // Manual error handling
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    // Manual form implementation
  );
};
```

### Form Validation

**Use react-hook-form's built-in validation:**

```typescript
// ✅ DO: Use comprehensive validation rules
type FormData = {
  email: string;
  password: string;
  confirmPassword: string;
};

const validationRules = {
  email: {
    required: "Email is required",
    pattern: {
      value: /^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$/i,
      message: "Invalid email address",
    },
  },
  password: {
    required: "Password is required",
    minLength: {
      value: 8,
      message: "Password must be at least 8 characters",
    },
    pattern: {
      value: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/,
      message: "Password must contain uppercase, lowercase, and number",
    },
  },
  confirmPassword: {
    required: "Please confirm your password",
    validate: (value: string, formValues: FormData) =>
      value === formValues.password || "Passwords do not match",
  },
};

// ✅ DO: Use custom validation functions
const useCustomValidation = () => {
  const validateUniqueEmail = async (email: string) => {
    const isAvailable = await checkEmailAvailability(email);
    return isAvailable || "Email is already taken";
  };

  return {
    email: {
      required: "Email is required",
      validate: validateUniqueEmail,
    },
  };
};

// ❌ DON'T: Skip validation or use manual validation
const BadForm = () => {
  const [email, setEmail] = useState("");

  const handleSubmit = () => {
    if (email.includes("@")) {
      // Basic manual validation
      submitForm();
    }
  };
};
```

### Form State Management

**Leverage react-hook-form's state management:**

```typescript
// ✅ DO: Use form state for UI updates
const MyForm = () => {
  const {
    control,
    handleSubmit,
    watch,
    formState: { isDirty, isValid, isSubmitting, errors },
    reset,
    setValue,
    getValues,
  } = useForm<FormData>();

  const watchedFields = watch(); // Watch all fields
  const watchedEmail = watch("email"); // Watch specific field

  const isFormValid = isValid && isDirty;
  const hasErrors = Object.keys(errors).length > 0;

  return (
    <View>
      {/* Show form status */}
      {isDirty && (
        <CommonText className="text-yellow-400 text-sm">
          You have unsaved changes
        </CommonText>
      )}

      {hasErrors && (
        <CommonText className="text-red-400 text-sm">
          Please fix the errors above
        </CommonText>
      )}

      {/* Conditional submit button */}
      <FancyButton
        text="Submit"
        onPress={handleSubmit(onSubmit)}
        disabled={!isFormValid || isSubmitting}
      />
    </View>
  );
};

// ✅ DO: Use reset and setValue for programmatic control
const useFormActions = () => {
  const { reset, setValue, getValues } = useForm<FormData>();

  const loadUserData = (userData: User) => {
    reset({
      email: userData.email,
      name: userData.name,
    });
  };

  const updateField = (field: keyof FormData, value: string) => {
    setValue(field, value, { shouldValidate: true });
  };

  const getFormData = () => getValues();

  return { loadUserData, updateField, getFormData };
};

// ❌ DON'T: Manage form state manually
const BadFormState = () => {
  const [formData, setFormData] = useState<FormData>({});
  const [isDirty, setIsDirty] = useState(false);
  const [errors, setErrors] = useState<Record<string, string>>({});

  // Manual state management
  const updateField = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }));
    setIsDirty(true);
    // Manual validation
  };
};
```

### Form Submission and Error Handling

**Handle form submission with proper error management:**

```typescript
// ✅ DO: Comprehensive form submission handling
const useFormSubmission = () => {
  const {
    handleSubmit,
    setError,
    clearErrors,
    formState: { isSubmitting },
  } = useForm<FormData>();

  const onSubmit = async (data: FormData) => {
    try {
      clearErrors(); // Clear any previous errors

      const response = await submitForm(data);

      if (response.success) {
        showSuccessMessage("Form submitted successfully!");
        // Handle success (navigate, reset form, etc.)
      } else {
        // Handle API validation errors
        if (response.errors) {
          Object.entries(response.errors).forEach(([field, message]) => {
            setError(field as keyof FormData, {
              type: "server",
              message: message as string,
            });
          });
        }
      }
    } catch (error) {
      // Handle network or unexpected errors
      setError("root", {
        type: "server",
        message: "An unexpected error occurred. Please try again.",
      });
    }
  };

  return {
    onSubmit: handleSubmit(onSubmit),
    isSubmitting,
  };
};

// ✅ DO: Show field-specific and general errors
const FormWithErrors = () => {
  const {
    control,
    formState: { errors },
  } = useForm<FormData>();

  return (
    <View>
      {/* Field-specific errors */}
      <Controller
        control={control}
        name="email"
        render={({ field }) => (
          <View>
            <TextInput {...field} />
            {errors.email && (
              <CommonText className="text-red-400 text-sm">
                {errors.email.message}
              </CommonText>
            )}
          </View>
        )}
      />

      {/* General form errors */}
      {errors.root && (
        <View className="bg-red-500/10 border border-red-500/20 rounded-lg p-3 mb-4">
          <CommonText className="text-red-400 text-sm">
            {errors.root.message}
          </CommonText>
        </View>
      )}
    </View>
  );
};

// ❌ DON'T: Ignore error handling
const BadSubmission = () => {
  const handleSubmit = async (data: FormData) => {
    await submitForm(data); // No error handling
  };
};
```

### Form Performance

**Optimize form performance with proper memoization:**

```typescript
// ✅ DO: Memoize form components
const MemoizedFormField = React.memo(
  ({ control, name, rules, ...props }: FormFieldProps) => {
    return (
      <Controller
        control={control}
        name={name}
        rules={rules}
        render={({ field, fieldState }) => (
          <View>
            <TextInput {...field} {...props} />
            {fieldState.error && (
              <CommonText className="text-red-400 text-sm">
                {fieldState.error.message}
              </CommonText>
            )}
          </View>
        )}
      />
    );
  }
);

// ✅ DO: Use useCallback for form handlers
const FormComponent = () => {
  const { control, handleSubmit } = useForm<FormData>();

  const onSubmit = useCallback(async (data: FormData) => {
    await submitForm(data);
  }, []);

  const onReset = useCallback(() => {
    reset();
  }, [reset]);

  return (
    <View>
      <MemoizedFormField
        control={control}
        name="email"
        rules={{ required: "Email is required" }}
      />
      <FancyButton onPress={handleSubmit(onSubmit)} text="Submit" />
      <FancyButton onPress={onReset} text="Reset" />
    </View>
  );
};

// ❌ DON'T: Create new functions on every render
const BadFormPerformance = () => {
  const { control, handleSubmit } = useForm<FormData>();

  return (
    <View>
      <Controller
        control={control}
        name="email"
        render={({ field }) => (
          <TextInput
            {...field}
            onChangeText={(text) => {
              // New function on every render
              field.onChange(text);
            }}
          />
        )}
      />
    </View>
  );
};
```

**Reasons for using react-hook-form:**

- **Performance**: Minimal re-renders compared to controlled components
- **Validation**: Built-in validation with excellent TypeScript support
- **Developer Experience**: Declarative API with less boilerplate
- **Error Handling**: Comprehensive error management and display
- **Accessibility**: Better form accessibility out of the box
- **Bundle Size**: Smaller bundle size compared to alternatives
- **TypeScript**: Excellent TypeScript support with type inference

## Styling Guidelines

### NativeWind (Tailwind CSS)

**Always use NativeWind for styling:**

```typescript
// ✅ DO: Use Tailwind classes
<View className="flex-1 p-4 bg-white rounded-lg shadow-sm">
  <Text className="text-lg font-semibold text-gray-900">Title</Text>
</View>;

// ❌ DON'T: Use StyleSheet
const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
});
```

### View Components

**Use plain View components since the app has only one theme:**

```typescript
// ✅ DO: Use plain View with NativeWind styling
<View className="p-4 rounded-xl">
  <CommonText className="text-xl font-bold text-white">Title</CommonText>
  <CommonText className="text-lg text-white/80">Subtitle</CommonText>
</View>

// ❌ DON'T: Use ThemedView (unnecessary for single-theme app)
<ThemedView className="p-4 rounded-xl">
  <CommonText className="text-xl font-bold text-white">Title</CommonText>
</ThemedView>
```

**Why not use ThemedView:**

- The app has only one theme (dark theme)
- ThemedView adds unnecessary complexity for single-theme apps
- Plain View with NativeWind classes provides the same functionality
- Simpler and more maintainable code

### Text Components

**Always use CommonText instead of ThemedText for better font consistency:**

```typescript
// ✅ DO: Use CommonText with explicit styling
<CommonText className="text-xl font-bold text-white">
  Title Text
</CommonText>

<CommonText className="text-base text-white/70">
  Body text with proper font family
</CommonText>

<CommonText type="playfull" className="text-lg text-pink-400">
  Playful text with PatrickHand font
</CommonText>

// ❌ DON'T: Use ThemedText or plain Text
<ThemedText type="title">Title</ThemedText>
<Text>Plain text without font family</Text>
```

**CommonText Features:**

- **Font Family**: Automatically applies Comfortaa font family for consistent typography
- **Playful Type**: Use `type="playfull"` for PatrickHand font (handwritten style)
- **NativeWind Support**: Full Tailwind CSS class support
- **Consistent Styling**: Ensures all text uses the app's design system fonts

**When to use each type:**

- `type="default"` (default): For all standard text using Comfortaa font
- `type="playfull"`: For special text that needs a handwritten feel using PatrickHand font

### Responsive Design

**Use responsive Tailwind classes:**

```typescript
// ✅ DO: Responsive design
<View className="p-4 md:p-6 lg:p-8">
  <Text className="text-sm md:text-base lg:text-lg">Responsive text</Text>
</View>
```

## File Organization

### Component Structure

**Organize components in feature-based folders:**

```
components/
  features/
    FeatureName/
      ComponentName/
        index.tsx
        SubComponent/
          index.tsx
        hooks/
          useHookName/
            index.ts
```

### Hook Organization

**Create custom hooks for reusable logic:**

```typescript
// ✅ DO: Extract logic into custom hooks
const useUserData = () => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchUser = useCallback(async () => {
    // fetch logic
  }, []);

  return { user, loading, fetchUser };
};
```

### Type Definitions

**Keep types close to their usage:**

```typescript
// ✅ DO: Define types in the same file or nearby
type ComponentProps = {
  // props
};

const Component = ({ prop }: ComponentProps) => {
  // component logic
};
```

### Import Path Preferences

**Use absolute imports for deep imports, relative imports for nearby files:**

```typescript
// ✅ DO: Use absolute imports when going up multiple levels
import { SomeComponent } from "@/components/features/SomeFeature";
import { useHook } from "@/hooks/useHookName";
import { utils } from "@/utils/common";

// ✅ DO: Use relative imports for same level or one level up
import { SubComponent } from "./SubComponent";
import { ParentComponent } from "../ParentComponent";
import { SiblingComponent } from "./SiblingComponent";

// ❌ DON'T: Use relative imports with multiple ../ when absolute is available
import { SomeComponent } from "../../../features/SomeFeature";
import { useHook } from "../../../../hooks/useHookName";
```

**Rules:**

- Use `@/` absolute imports when you need `../` more than once
- Use relative imports (`./` or `../`) for same level or one level up
- This makes imports more readable and maintainable
- Avoid deep relative path chains like `../../../`

## Performance Guidelines

### List Rendering

**Use FlatList for large lists:**

```typescript
// ✅ DO: Use FlatList for performance
<FlatList
  data={items}
  renderItem={renderItem}
  keyExtractor={(item) => item.id}
  showsVerticalScrollIndicator={false}
/>

// ❌ DON'T: Use ScrollView with map for large lists
<ScrollView>
  {items.map(item => <Item key={item.id} />)}
</ScrollView>
```

### Image Optimization

**Use proper image sizing and caching:**

```typescript
// ✅ DO: Optimize images
<Image
  source={require("./image.png")}
  className="w-20 h-20 rounded-full"
  resizeMode="cover"
/>;

// ✅ DO: Use FastImage for remote images
import FastImage from "react-native-fast-image";

<FastImage
  source={{ uri: imageUrl }}
  className="w-full h-48"
  resizeMode={FastImage.resizeMode.cover}
/>;
```

### Memory Management

**Clean up subscriptions and timers:**

```typescript
// ✅ DO: Clean up in useEffect
useEffect(() => {
  const subscription = someService.subscribe();

  return () => {
    subscription.unsubscribe();
  };
}, []);
```

## Error Handling

### Try-Catch Blocks

**Always handle errors gracefully:**

```typescript
// ✅ DO: Proper error handling
const handleAsyncOperation = async () => {
  try {
    setLoading(true);
    const result = await apiCall();
    setData(result);
  } catch (error) {
    console.error("Operation failed:", error);
    setError(error.message);
  } finally {
    setLoading(false);
  }
};
```

### Error Boundaries

**Use error boundaries for component error handling:**

```typescript
// ✅ DO: Error boundary component
class ErrorBoundary extends React.Component {
  state = { hasError: false };

  static getDerivedStateFromError(error: Error) {
    return { hasError: true };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error("Error caught:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return <ErrorFallback />;
    }

    return this.props.children;
  }
}
```

## Testing Guidelines

### Component Testing

**Write tests for all components:**

```typescript
// ✅ DO: Test component rendering
describe("MyComponent", () => {
  it("renders correctly", () => {
    render(<MyComponent title="Test" />);
    expect(screen.getByText("Test")).toBeTruthy();
  });

  it("handles user interactions", () => {
    const onPress = jest.fn();
    render(<MyComponent onPress={onPress} />);

    fireEvent.press(screen.getByText("Button"));
    expect(onPress).toHaveBeenCalled();
  });
});
```

### Hook Testing

**Test custom hooks:**

```typescript
// ✅ DO: Test custom hooks
describe("useCustomHook", () => {
  it("returns expected values", () => {
    const { result } = renderHook(() => useCustomHook());
    expect(result.current.value).toBe(expectedValue);
  });
});
```

## Accessibility

### Screen Reader Support

**Add accessibility props:**

```typescript
// ✅ DO: Accessibility support
<TouchableOpacity
  accessible={true}
  accessibilityLabel="Submit button"
  accessibilityHint="Double tap to submit the form"
  onPress={handleSubmit}
>
  <Text>Submit</Text>
</TouchableOpacity>
```

### Color Contrast

**Ensure proper color contrast:**

```typescript
// ✅ DO: Use semantic colors
<Text className="text-gray-900 dark:text-gray-100">
  High contrast text
</Text>

// ❌ DON'T: Use low contrast colors
<Text style={{ color: '#ccc' }}>
  Low contrast text
</Text>
```

## API Specification Updates

### How to Update API Specifications

When the user requests "update api specs", follow this process:

1. **Fetch the current OpenAPI specification:**

   ```bash
   curl -s http://localhost:3000/docs/as_json
   ```

2. **Parse the OpenAPI JSON and identify changes:**

   - Compare with existing `API_SPECIFICATION.md`
   - Look for new endpoints, updated schemas, or changed responses
   - Note any new error codes or response types

3. **Update the API_SPECIFICATION.md file:**

   - Add new endpoints with proper numbering
   - Update existing endpoint documentation if needed
   - Add new data models and response types
   - Update examples and error responses
   - Maintain the existing format and structure

4. **Key areas to check for updates:**

   - New endpoints (GET, POST, PUT, DELETE)
   - Updated schema definitions
   - New response types
   - Additional error codes
   - Changed field requirements (required vs optional)
   - New query parameters or headers

5. **Maintain consistency:**

   - Keep the same documentation format
   - Use consistent numbering for endpoints
   - Preserve existing examples and descriptions
   - Update the data models section with new types

6. **Verify the update:**
   - Ensure all endpoints are documented
   - Check that response examples match the OpenAPI spec
   - Verify error responses are complete
   - Confirm data models are up to date

### Example Update Process

```bash
# 1. Fetch current spec
curl -s http://localhost:3000/docs/as_json > current_spec.json

# 2. Compare with existing documentation
# 3. Update API_SPECIFICATION.md with changes
# 4. Verify all endpoints are documented
# 5. Update any related TypeScript types if needed
```

## General Guidelines

- **Consistency over minor optimizations**
- **Explicit over implicit**
- **Types for everything** - no interfaces
- **Use intersection types** for composition
- **Prefer union types** for alternatives
- **Performance first** - optimize for mobile
- **Accessibility by default** - make apps usable for everyone
- **Test everything** - maintain code quality
- **Document complex logic** - help future developers

## Code Style

- Use `type` for all type definitions
- Use intersection types (`&`) for extending
- Use union types (`|`) for alternatives
- Use mapped types for transformations
- Keep types simple and focused
- Use NativeWind for all styling
- Prefer functional components with hooks
- Extract reusable logic into custom hooks
- Handle errors gracefully
- Write tests for all components
- Ensure accessibility compliance
