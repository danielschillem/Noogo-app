import { describe, it, expect, vi, beforeEach } from 'vitest';

/**
 * Tests des fonctions API (authApi, couponsApi)
 *
 * On mock axios directement plutôt que les fonctions api.ts
 * pour tester les bons endpoints et paramètres.
 */

vi.mock('axios', () => {
    const mockAxios = {
        create: vi.fn().mockReturnValue({
            get: vi.fn(),
            post: vi.fn(),
            put: vi.fn(),
            delete: vi.fn(),
            patch: vi.fn(),
            interceptors: {
                request: { use: vi.fn() },
                response: { use: vi.fn() },
            },
        }),
    };
    return { default: mockAxios };
});

// Import AFTER mock is set up
import axios from 'axios';
import { authApi, couponsApi, restaurantsApi } from '../services/api';

const mockApi = axios.create();

describe('authApi', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('login appelle POST /auth/login avec email et password', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: { success: true } });

        await authApi.login('user@test.com', 'secret');

        expect(mockApi.post).toHaveBeenCalledWith('/auth/login', {
            email: 'user@test.com',
            password: 'secret',
        });
    });

    it('logout appelle POST /auth/logout', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: { success: true } });

        await authApi.logout();

        expect(mockApi.post).toHaveBeenCalledWith('/auth/logout');
    });

    it('me appelle GET /auth/me', async () => {
        (mockApi.get as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await authApi.me();

        expect(mockApi.get).toHaveBeenCalledWith('/auth/me');
    });

    it('forgotPassword appelle POST /auth/forgot-password', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await authApi.forgotPassword('user@test.com');

        expect(mockApi.post).toHaveBeenCalledWith('/auth/forgot-password', {
            email: 'user@test.com',
        });
    });

    it('resetPassword appelle POST /auth/reset-password avec token et passwords', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await authApi.resetPassword({
            token: 'abc123',
            password: 'newpass',
            password_confirmation: 'newpass',
        });

        expect(mockApi.post).toHaveBeenCalledWith('/auth/reset-password', {
            token: 'abc123',
            password: 'newpass',
            password_confirmation: 'newpass',
        });
    });

    it('changePassword appelle POST /auth/change-password', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await authApi.changePassword({
            current_password: 'old',
            password: 'new',
            password_confirmation: 'new',
        });

        expect(mockApi.post).toHaveBeenCalledWith('/auth/change-password', {
            current_password: 'old',
            password: 'new',
            password_confirmation: 'new',
        });
    });

    it('register appelle POST /auth/register', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await authApi.register({
            name: 'Test',
            email: 'test@test.com',
            password: 'pass',
            password_confirmation: 'pass',
        });

        expect(mockApi.post).toHaveBeenCalledWith('/auth/register', {
            name: 'Test',
            email: 'test@test.com',
            password: 'pass',
            password_confirmation: 'pass',
        });
    });
});

describe('couponsApi', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('getAll appelle GET avec le bon restaurantId', async () => {
        (mockApi.get as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: { data: [] } });

        await couponsApi.getAll(42);

        expect(mockApi.get).toHaveBeenCalledWith('/restaurants/42/coupons');
    });

    it('create appelle POST sur le bon endpoint', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await couponsApi.create(42, { code: 'TEST', type: 'percentage', value: 10 });

        expect(mockApi.post).toHaveBeenCalledWith(
            '/restaurants/42/coupons',
            { code: 'TEST', type: 'percentage', value: 10 },
        );
    });

    it('toggleActive appelle POST toggle-active', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await couponsApi.toggleActive(42, 7);

        expect(mockApi.post).toHaveBeenCalledWith('/restaurants/42/coupons/7/toggle-active');
    });

    it('delete appelle DELETE sur le bon endpoint', async () => {
        (mockApi.delete as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await couponsApi.delete(42, 7);

        expect(mockApi.delete).toHaveBeenCalledWith('/restaurants/42/coupons/7');
    });

    it('update appelle PUT avec les bonnes données', async () => {
        (mockApi.put as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await couponsApi.update(42, 7, { value: 20, is_active: false });

        expect(mockApi.put).toHaveBeenCalledWith(
            '/restaurants/42/coupons/7',
            { value: 20, is_active: false },
        );
    });
});

describe('restaurantsApi', () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it('getAll appelle GET /restaurants', async () => {
        (mockApi.get as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await restaurantsApi.getAll();

        expect(mockApi.get).toHaveBeenCalledWith('/restaurants', { params: undefined });
    });

    it('getById appelle GET /restaurants/:id', async () => {
        (mockApi.get as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await restaurantsApi.getById(5);

        expect(mockApi.get).toHaveBeenCalledWith('/restaurants/5');
    });

    it('toggleActive appelle POST toggle-active', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await restaurantsApi.toggleActive(3);

        expect(mockApi.post).toHaveBeenCalledWith('/restaurants/3/toggle-active');
    });

    it('toggleOpen appelle POST toggle-open', async () => {
        (mockApi.post as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await restaurantsApi.toggleOpen(3);

        expect(mockApi.post).toHaveBeenCalledWith('/restaurants/3/toggle-open');
    });

    it('delete appelle DELETE /restaurants/:id', async () => {
        (mockApi.delete as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ data: {} });

        await restaurantsApi.delete(8);

        expect(mockApi.delete).toHaveBeenCalledWith('/restaurants/8');
    });
});
