# Frontend Documentation - Skill Tracker

## Overview

The Skill Tracker frontend is an Angular application hosted on AWS Amplify with CloudFront CDN distribution. It provides the user interface for all 12 microservices and handles OAuth authentication flows.

## Technology Stack

- **Framework**: Angular
- **Hosting**: AWS Amplify
- **CDN**: CloudFront (managed by Amplify)
- **Build Tool**: npm/Angular CLI
- **Authentication**: OAuth 2.0 (Google)
- **State Management**: Angular Services
- **HTTP Client**: Angular HttpClient

## Architecture

```
User Browser
    ↓
CloudFront Distribution (CDN)
    ↓
AWS Amplify (Static Hosting)
    ↓
S3 Bucket (Build Artifacts)
    
API Calls:
User Browser → CloudFront → API Gateway → Microservices
```

## AWS Amplify Configuration

### Build Specification

The application uses a custom build specification configured in Terraform:

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci  # Deterministic builds (uses package-lock.json)
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: dist/angular-app
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
```

### Key Configuration Details

- **Build Command**: `npm ci` (not `npm install`) for reproducible builds
- **Output Directory**: `dist/angular-app`
- **Caching**: `node_modules` cached between builds
- **Auto Deploy**: Triggered on git push to connected branch

## CloudFront CDN Integration

### Sprint 3 Enhancements

CloudFront distribution was enhanced with:

1. **Managed Caching Policies**: AWS-managed policies for optimal performance
2. **Cache Behaviors**: Separate policies for static assets and API routes
3. **Header Forwarding**: Proper configuration for legacy caching support

### Caching Strategy

- **Static Assets** (JS, CSS, images): Long TTL (1 year)
- **HTML Files**: Short TTL (5 minutes) for quick updates
- **API Calls**: No caching (pass-through to backend)

### Cache Invalidation

After deployment, Amplify automatically invalidates:
- `/*` (all paths)
- `/index.html`

## OAuth Configuration

### Google OAuth Integration

The application uses Google OAuth for authentication with the following configuration:

**Redirect URLs** (Updated in Sprint 3):
- Development: `https://<cloudfront-domain>/oauth/callback`
- Staging: `https://<cloudfront-domain>/oauth/callback`
- Production: `https://<cloudfront-domain>/oauth/callback`

**Environment Variables**:
```typescript
GOOGLE_CLIENT_ID=<from-secrets-manager>
GOOGLE_CLIENT_SECRET=<from-secrets-manager>
API_GATEWAY_URL=<from-terraform-outputs>
```

### OAuth Flow

1. User clicks "Login with Google"
2. Redirected to Google OAuth consent screen
3. User authorizes application
4. Google redirects to CloudFront callback URL
5. Frontend exchanges code for token via backend
6. User redirected to intended page (not homepage)

**Sprint 3 Fix**: Resolved issue where users were incorrectly redirected to homepage after login.

## Environment Configuration

### Development Environment

```typescript
export const environment = {
  production: false,
  apiUrl: 'https://<dev-cloudfront-domain>',
  googleClientId: '<dev-client-id>',
  cookieSecure: false
};
```

### Production Environment

```typescript
export const environment = {
  production: true,
  apiUrl: 'https://<prod-cloudfront-domain>',
  googleClientId: '<prod-client-id>',
  cookieSecure: true
};
```

## Routing Configuration

### Angular Router

The application uses Angular Router with the following configuration:

```typescript
const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'dashboard', component: DashboardComponent },
  { path: 'oauth/callback', component: OAuthCallbackComponent },
  { path: 'tasks', component: TasksComponent },
  { path: 'skills', component: SkillsComponent },
  // ... other routes
  { path: '**', redirectTo: '/dashboard' }
];
```

### CloudFront Redirects

To support Angular routing (SPA), CloudFront is configured to:
- Return `index.html` for all non-file requests
- Preserve URL path for Angular Router

## API Integration

### HTTP Interceptor

All API calls go through an HTTP interceptor that:

1. Adds authentication token to headers
2. Handles 401 (unauthorized) responses
3. Retries failed requests
4. Logs errors to console

```typescript
@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = this.authService.getToken();
    if (token) {
      req = req.clone({
        setHeaders: {
          Authorization: `Bearer ${token}`
        }
      });
    }
    return next.handle(req);
  }
}
```

### API Endpoints

The frontend communicates with 12 microservices through API Gateway:

| Service | Endpoint | Purpose |
|---------|----------|---------|
| User Service | `/api/users` | User management, authentication |
| Task Service | `/api/tasks` | Task CRUD operations |
| Skill Service | `/api/skills` | Skill tracking |
| Assessment Service | `/api/assessments` | Assessments and quizzes |
| Analytics Service | `/api/analytics` | Usage analytics |
| Feedback Service | `/api/feedback` | User feedback |
| Notification Service | `/api/notifications` | Real-time notifications |
| Report Service | `/api/reports` | Report generation |
| Recommendation Service | `/api/recommendations` | Personalized recommendations |
| Search Service | `/api/search` | Full-text search |
| Integration Service | `/api/integrations` | Third-party integrations |
| Collaboration Service | `/api/collaboration` | Team collaboration |

## Build Process

### Local Development

```bash
# Install dependencies
npm ci

# Run development server
npm start
# or
ng serve

# Access at http://localhost:4200
```

### Production Build

```bash
# Build for production
npm run build

# Output: dist/angular-app/
```

### Build Optimization

- **AOT Compilation**: Ahead-of-time compilation enabled
- **Tree Shaking**: Unused code removed
- **Minification**: JavaScript and CSS minified
- **Source Maps**: Generated for debugging (dev only)
- **Bundle Splitting**: Lazy-loaded modules

## Deployment

### Automatic Deployment (Amplify)

1. Developer pushes code to Git repository
2. Amplify detects changes
3. Amplify runs build process
4. Build artifacts uploaded to S3
5. CloudFront cache invalidated
6. New version live

**Deployment Time**: ~5-10 minutes

### Manual Deployment

```bash
# Build locally
npm run build

# Deploy using AWS CLI (if needed)
aws s3 sync dist/angular-app/ s3://<amplify-bucket>/ --delete
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

## Monitoring

### CloudWatch Metrics

Amplify provides metrics for:
- Build success/failure rate
- Build duration
- Deployment frequency

### Frontend Errors

Errors are logged to:
- Browser console (development)
- CloudWatch Logs (via API calls)
- Third-party error tracking (optional)

## Security

### Content Security Policy (CSP)

```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; 
               script-src 'self' 'unsafe-inline'; 
               style-src 'self' 'unsafe-inline'; 
               img-src 'self' data: https:; 
               connect-src 'self' https://*.amazonaws.com;">
```

### Cookie Security

**Sprint 3 Enhancement**: Set `COOKIE_SECURE=true` for production

```typescript
// Production only
document.cookie = `token=${token}; Secure; HttpOnly; SameSite=Strict`;
```

### HTTPS Enforcement

- All traffic forced to HTTPS via CloudFront
- HTTP requests automatically redirected to HTTPS

## Performance Optimization

### Lazy Loading

Modules are lazy-loaded to reduce initial bundle size:

```typescript
const routes: Routes = [
  {
    path: 'admin',
    loadChildren: () => import('./admin/admin.module').then(m => m.AdminModule)
  }
];
```

### Image Optimization

- Images served from CloudFront CDN
- Responsive images using `srcset`
- Lazy loading for below-the-fold images

### Bundle Analysis

```bash
# Analyze bundle size
npm run build -- --stats-json
npx webpack-bundle-analyzer dist/angular-app/stats.json
```

## Troubleshooting

### Issue: 404 on Page Refresh

**Cause**: CloudFront not configured to return `index.html` for SPA routes

**Solution**: Ensure CloudFront has custom error response:
- Error Code: 404
- Response Page Path: `/index.html`
- Response Code: 200

### Issue: OAuth Callback 404

**Cause**: Old redirect URLs pointing to ALB instead of CloudFront

**Solution** (Fixed in Sprint 3):
- Update Google OAuth redirect URLs to CloudFront domain
- Verify `LOGIN_URL` environment variable in backend

### Issue: API Calls Failing

**Cause**: CORS or incorrect API Gateway URL

**Solution**:
1. Verify `API_GATEWAY_URL` in environment config
2. Check CORS headers in API Gateway
3. Verify security group rules allow ALB → ECS traffic

### Issue: Slow Initial Load

**Cause**: Large bundle size or no caching

**Solution**:
1. Enable lazy loading for large modules
2. Verify CloudFront caching policies
3. Optimize images and assets
4. Use Angular production build

## Development Workflow

### Feature Development

1. Create feature branch: `git checkout -b feature/new-feature`
2. Develop locally: `npm start`
3. Test changes: `npm test`
4. Commit and push: `git push origin feature/new-feature`
5. Create pull request
6. Amplify creates preview environment
7. Review and merge to `dev` branch
8. Auto-deploy to dev environment

### Branch Deployments

Amplify can create preview environments for:
- Feature branches
- Pull requests
- Development branches

Each gets a unique URL: `https://<branch>.<app-id>.amplifyapp.com`

## Best Practices

1. **Use `npm ci`**: Ensures consistent builds across environments
2. **Environment Variables**: Never commit secrets; use Amplify environment variables
3. **Lazy Loading**: Load modules on-demand to reduce initial bundle
4. **Error Handling**: Implement global error handler for API failures
5. **Caching**: Leverage CloudFront caching for static assets
6. **Testing**: Write unit tests for components and services
7. **Accessibility**: Follow WCAG 2.1 guidelines
8. **Performance**: Monitor Core Web Vitals

## Future Enhancements

1. **Progressive Web App (PWA)**: Add service worker for offline support
2. **Server-Side Rendering (SSR)**: Use Angular Universal for SEO
3. **Internationalization (i18n)**: Support multiple languages
4. **Real-time Updates**: WebSocket integration for notifications
5. **Advanced Analytics**: Google Analytics or Mixpanel integration
6. **A/B Testing**: Feature flags and experimentation
7. **Error Tracking**: Sentry or Rollbar integration

## References

- [Angular Documentation](https://angular.io/docs)
- [AWS Amplify Hosting](https://docs.aws.amazon.com/amplify/latest/userguide/welcome.html)
- [CloudFront Developer Guide](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
