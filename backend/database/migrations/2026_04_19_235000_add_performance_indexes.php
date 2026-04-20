<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // Wrapped in try/catch: idempotent if indexes already exist
        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->index(['restaurant_id', 'order_date']);
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->index(['restaurant_id', 'status']);
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->index('order_date');
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('dishes', function (Blueprint $table) {
                $table->index(['restaurant_id', 'disponibilite']);
            });
        } catch (\Exception $e) {
        }
    }

    public function down(): void
    {
        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropIndex(['restaurant_id', 'order_date']);
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropIndex(['restaurant_id', 'status']);
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropIndex(['order_date']);
            });
        } catch (\Exception $e) {
        }

        try {
            Schema::table('dishes', function (Blueprint $table) {
                $table->dropIndex(['restaurant_id', 'disponibilite']);
            });
        } catch (\Exception $e) {
        }
    }
};
