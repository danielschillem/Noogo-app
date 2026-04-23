<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('oral_order_notes', function (Blueprint $table) {
            $table->foreignId('converted_order_id')
                ->nullable()
                ->after('validated_at')
                ->constrained('orders')
                ->nullOnDelete();
        });
    }

    public function down(): void
    {
        Schema::table('oral_order_notes', function (Blueprint $table) {
            $table->dropConstrainedForeignId('converted_order_id');
        });
    }
};
