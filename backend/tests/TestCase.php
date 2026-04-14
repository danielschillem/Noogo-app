<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        // Supprime E_WARNING de file_get_contents() sur le fichier maintenance
        // qui n'existe pas en test — comportement normal, app non en maintenance.
        error_reporting(E_ALL & ~E_WARNING);

        parent::setUp();
    }
}
