import { describe, it, expect } from 'vitest';
import {
    STAFF_ROLE_LABELS,
    STAFF_ROLE_COLORS,
    type StaffRole,
} from '../types';

/**
 * Tests des constantes d'affichage des rôles du personnel
 */
describe('STAFF_ROLE_LABELS', () => {
    const roles: StaffRole[] = ['owner', 'manager', 'cashier', 'waiter'];

    it('couvre tous les rôles définis', () => {
        expect(Object.keys(STAFF_ROLE_LABELS)).toHaveLength(4);
    });

    it.each(roles)('le rôle %s a un label non vide', (role) => {
        expect(STAFF_ROLE_LABELS[role]).toBeTruthy();
        expect(typeof STAFF_ROLE_LABELS[role]).toBe('string');
    });

    it('owner → "Propriétaire"', () => {
        expect(STAFF_ROLE_LABELS.owner).toBe('Propriétaire');
    });

    it('manager → "Gérant"', () => {
        expect(STAFF_ROLE_LABELS.manager).toBe('Gérant');
    });

    it('cashier → "Caissier"', () => {
        expect(STAFF_ROLE_LABELS.cashier).toBe('Caissier');
    });

    it('waiter → "Serveur"', () => {
        expect(STAFF_ROLE_LABELS.waiter).toBe('Serveur');
    });
});

describe('STAFF_ROLE_COLORS', () => {
    const roles: StaffRole[] = ['owner', 'manager', 'cashier', 'waiter'];

    it('couvre tous les rôles', () => {
        expect(Object.keys(STAFF_ROLE_COLORS)).toHaveLength(4);
    });

    it.each(roles)('le rôle %s a des classes CSS Tailwind non vides', (role) => {
        const classes = STAFF_ROLE_COLORS[role];
        expect(classes).toBeTruthy();
        // Doit contenir au moins une classe bg- et une classe text-
        expect(classes).toMatch(/bg-\w+/);
        expect(classes).toMatch(/text-\w+/);
    });

    it('chaque rôle a une couleur distincte', () => {
        const colors = roles.map((r) => STAFF_ROLE_COLORS[r]);
        const uniqueColors = new Set(colors);
        expect(uniqueColors.size).toBe(roles.length);
    });
});
